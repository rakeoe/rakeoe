# -*- ruby -*-

require 'rake'


module RakeOE

  # Finds all project files and reads them into memory
  # Maps project path => project file
  # XXX DS: IDEA: generate all runtime dependencies at the beginning for each prj,
  # XXX DS: e.g. lib includes, source files, dependency files etc. and cache those as own variable in @prj_list
  class PrjFileCache

    attr_accessor :prj_list

    # Introduce hash of projects. Contains list of project with key 'PRJ_TYPE'
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


    # Returns specific value of a setting of the specified
    # project
    def self.get(prj_type, prj_name, setting)
      return nil unless self.contain?(prj_type, prj_name)
      @prj_list[prj_type][prj_name][setting] || nil
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


    def self.for_each(prj_type, &block)
      return unless @prj_list.has_key?(prj_type)
      @prj_list[prj_type].each_pair &block
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
        h.merge!(@prj_list[prj_type].reverse) if @prj_list.has_key?(prj_type)
      end
    end

    #
    # SEMANTIC METHODS
    #


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
