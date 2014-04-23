# -*- ruby -*-

require 'rake'


module RakeOE
  
  # Finds all project files and reads them into memory
  # Maps project path => project file
  # XXX DS: IDEA: generate all runtime dependencies at the beginning for each prj,
  # XXX DS: e.g. lib includes, source files, dependency files etc. and cache those as own variable in @prj_list
  class PrjFileCache

    # Introduce hash of projects. Contains list of project with key 'PRJ_TYPE'
    @prj_list = {}

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
  end
end