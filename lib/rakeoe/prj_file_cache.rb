# -*- ruby -*-

require 'rake'


module RakeOE

  # Finds all project files and reads them into memory
  # Maps found entries to the following hash format:
  #
  #  {"PRJ_TYPE1" => [{"NAME1"=>{"SETTING1" => "VALUE1", "SETTING2" => "VALUE2", ... },
  #                   {"NAME2"=>{"SETTING1" => "VALUE1", "SETTING2" => "VALUE2", ... },
  #                    ... ,
  #                  ]
  #  {"PRJ_TYPE2" => [{"NAME100"=>{"SETTING1" => "VALUE1", "SETTING2" => "VALUE2", ... },
  #                   {"NAME101"=>{"SETTING1" => "VALUE1", "SETTING2" => "VALUE2", ... },
  #                   ... ,
  #                  ]
  #  }
  # XXX DS: IDEA: generate all runtime dependencies at the beginning for each prj,
  # XXX DS: e.g. lib includes, source files, dependency files etc. and cache those as own variable in @prj_list
  class PrjFileCache

    class << self; attr_accessor :prj_list end

    # Introduce class instance variable: hash of projects.
    # Contains list of project with key 'PRJ_TYPE'
    @prj_list = {}

    #
    # GENERIC METHODS
    #

    # Sets default properties that should be included for every found project file
    def self.set_defaults(properties)
      @defaults = properties
    end

    # Search, read and parse all project files in given directories and add them to prj_list according
    # to their PRJ_TYPE setting.
    # @param dirs   List of directories to search recursively for prj.rake files
    #
    def self.sweep_recursive(dirs=[])
      globs = dirs.map{|dir| dir+'/**/prj.rake'}
      all_prj_files = FileList[globs]
      raise "No projects inside #{dirs}?!" if all_prj_files.empty?

      all_prj_files.each do |file|
        # extract last path from prj.rake as project name
        dir = File.dirname(file)
        name = File.basename(dir)
        kvr = KeyValueReader.new(file)
        kvr.merge(@defaults)

        prj_type = kvr.get('PRJ_TYPE')

        raise "Attribute PRJ_TYPE not set in #{dir}/prj.rake" if prj_type.empty?

        # add attribute PRJ_HOME
        kvr.set('PRJ_HOME', dir)
        kvr.set('PRJ_FILE', file)
        @prj_list[prj_type] ||= {}
        if @prj_list[prj_type].member?(name)
          raise "#{dir}/prj.rake: project \"#{name}\" for PRJ_TYPE \'#{prj_type}\' already defined in #{@prj_list[prj_type][name]['PRJ_HOME']}"
          # XXX we should use a new attribute PRJ_NAME for conflicting project names ...
        end

        @prj_list[prj_type].merge!({name => kvr.env})
      end
    end


    # Returns specific project library settings with given library names
    #
    # @param libs   Name of libraries
    #
    def self.get_lib_entries(libs)
      rv = {}
      self.entries_reversed(['ALIB', 'SOLIB']).each_pair do |entries, prj_name|
        if libs.include?(prj_name)
          rv[prj_name] = entries
        end
      end
      rv
    end


    # Returns specific value of a setting of the specified
    # project
    def self.get(prj_type, prj_name, setting)
      return nil unless self.contain?(prj_type, prj_name)
      @prj_list[prj_type][prj_name][setting] || nil
    end


    # Returns specific value of a setting of the specified
    # project
    def self.get_with_name(prj_name, setting)
      projects = @prj_list.values.flatten
      projects.each do |project|
        values = project[prj_name]
        if values
          value = values[setting].split
          if value
            return value
          else
            return []
          end
        end
      end
      []
    end

    # Do we know anything about prj_name ?
    def self.contain?(prj_type, prj_name)
      return false unless @prj_list.has_key?(prj_type)
      @prj_list[prj_type].has_key?(prj_name)
    end


    # Returns all found project names
    def self.project_names(prj_type)
      return [] unless @prj_list.has_key?(prj_type)
      @prj_list[prj_type].keys
    end


    # Returns the directory in which the prj is
    def self.directory(prj_type, prj_name)
      return nil unless self.contain?(prj_type, prj_name)
      @prj_list[prj_type][prj_name]['PRJ_HOME']
    end

    # iterate over each project with given project type
    def self.for_each(prj_type, &block)
      return unless @prj_list.has_key?(prj_type)
      @prj_list[prj_type].each_pair &block
    end


    #
    # Recursive function that uses each value of the array given via
    # parameter 'values' and uses parameter 'setting' for accessing the
    # values for next recursion step until all values have been traversed
    # in all projects
    def self.deps_recursive(values, setting, visited=Set.new)
      return visited if values.nil?
      values.each do |val|
        next if (visited.include?(val))
        visited << val
        next_values = PrjFileCache.get_with_name(val, setting)
        deps_recursive(next_values, setting, visited)
      end
      visited
    end


    # Searches recursively for all projects with name and associate
    # Dependency with given attribute
    #
    # Returns a hash of the following form:
    # { 'name1' => ['name2', 'name3', ...],
    #   'name2' => ['name1', 'name3', ...],
    #   'name3' => ['name1', 'name5', ...],
    # }
    #
    def self.search_recursive(params={})
      attribute = params[:attribute]
      names = params[:names]
      rv = {}
      @prj_list.values.flatten.each do |projects|
        projects.each_pair do |prj_name, prj_attributes|
          if (names.include?(prj_name))
            attr_values = prj_attributes[attribute].split
            dependencies = deps_recursive(attr_values, attribute)
            rv[prj_name] = dependencies.to_a
          end
        end
      end
      rv
    end


    # Returns all entries for given project types as an array
    # of reversed prj_name => prj_type mappings
    #
    # @param prj_types [Array]    project types as defined by the PRJ_TYPE property
    #
    # @return [Array]   Array of hashes prj_name => prj_type
    #
    def self.entries_reversed(prj_types)
      prj_types.each_with_object(Hash.new) do |prj_type, h|
        h.merge!(@prj_list[prj_type].invert) if @prj_list.has_key?(prj_type)
      end
    end


    #
    # SEMANTIC METHODS, use specific attributes
    #


    # Checks if the project entries build prerequisites are met.
    #
    # If at least one of the following criteria are met, the method returns false:
    #   * project variable PRJ_TYPE == "DISABLED"
    #   * project variable IGNORED_PLATFORMS contains build platform
    #
    # @param    entry       The project name
    # @param    platform    Current platform
    #
    # @return   true    if project can be built on current platform
    # @return   false   if project settings prohibit building
    #
    def self.project_entry_buildable?(entry, platform)
      (entry['IGNORED_PLATFORMS'].include?(platform)) &&
          (entry['PRJ_TYPE'] != 'DISABLED')
    end

=begin
    # Checks if projects build prerequisites are met.
    #
    # If at least one of the following criteria are met, the method returns false:
    #   * project variable PRJ_TYPE == "DISABLED"
    #   * project variable IGNORED_PLATFORMS contains build platform
    #
    # @param    prj_type  The project type
    # @param    prj_name  The project name
    # @param    platform  Current platform
    #
    # @return   true      if project can be built on current platform
    # @return   false     if project settings prohibit building
    #
    def self.project_can_build?(prj_type, prj_name, platform)
      self.project_entry_buildable?(@prj_list[prj_type][prj_name], platform)
    end
=end

    # Joins all entries with keys that are appended with a regular expression that match
    # the given match_string. Make them available via the base key name without the
    # regular expression.
    #
    # @param a_string   String to be matched against key in all kvr with appended regular expression
    #
    def self.join_regex_keys_for!(a_string)
      @prj_list.each_pair do |prj_type, prj_names|
        prj_names.each_pair do |prj_name, defs|
          defs.each_pair do |property, value|
            # split properties containing /../
            base, key_regex = property.split(/\//)
            if (key_regex)
              if a_string.match(Regexp.new(key_regex))
                if base.end_with?('_')
                  base_key = base.chop
                else
                  base_key = base
                end

                # if base_key does not yet exist, create an empty string
                @prj_list[prj_type][prj_name][base_key] ||= ''
                @prj_list[prj_type][prj_name][base_key] += " #{@prj_list[prj_type][prj_name][property]}"
              end
            end
          end
        end
      end
    end


    # Returns exported include directories of a library project.
    # If given name does not exist in local library projects, an empty array
    # is returned.
    #
    # @param  name    name of library
    #
    # @return         exported library includes
    #
    def self.exported_lib_incs(name)
      rv = []
      # try LIB
      exported_inc_dirs = self.get('LIB', name, 'EXPORTED_INC_DIRS')
      if exported_inc_dirs.to_s.empty?
        # try SOLIB
        exported_inc_dirs = self.get('SOLIB', name, 'EXPORTED_INC_DIRS')
        unless exported_inc_dirs.to_s.empty?
          exported_inc_dirs.split.each do |dir|
            rv << self.get('SOLIB', name, 'PRJ_HOME') + '/' + dir
          end
        end
      else
        exported_inc_dirs.split.each do |dir|
          rv << self.get('LIB', name, 'PRJ_HOME') + '/' + dir
        end
      end
      rv
    end


  end
end
