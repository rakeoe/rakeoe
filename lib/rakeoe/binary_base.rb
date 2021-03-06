# -*- ruby -*-
require 'rake'

# XXX DS: here we should use Rake::pathmap for all mapping of source => destination files

module RakeOE

  # Base class for all projects that assemble binary data
  class BinaryBase
    include Rake::DSL

    attr_reader   :build_dir, :src_dir, :src_dirs, :inc_dirs, :test_dirs, :obj_dirs

    attr_accessor :name, :bin_dir, :test_dir, :settings, :tc, :prj_file, :binary, :objs,
                  :deps, :test_deps, :test_binary, :test_objs

    #
    # The following parameters are expected in given hash params:
    #
    # @param  [Hash] params
    # @option params [String] :name        Name of the binary
    # @option params [String] :src_dir     Base source directory
    # @option params [String] :bin_dir     Output binary directory
    # @option params [String] :toolchain   Toolchain builder to use
    #
    def initialize(params)
      check_params(params)
      @@all_libs ||= (PrjFileCache.project_names('LIB') + PrjFileCache.project_names('SOLIB')).uniq
      @@all_libs_and_deps ||= PrjFileCache.search_recursive(:names => @@all_libs, :attribute => 'ADD_LIBS')
      @name = params[:name]
      @settings = params[:settings]
      @src_dir = @settings['PRJ_HOME']
      @bin_dir = params[:bin_dir]
      @tc = params[:toolchain]

      # derived parameters
      @build_dir = "#{@bin_dir}/.#{@name}"
      @binary = '.delete_me'

      @src_dirs  = src_directories(src_dir, @settings['ADD_SOURCE_DIRS'].split, :subdir_only => false)
      @test_dirs = src_directories(src_dir, @settings['TEST_SOURCE_DIRS'].split, :subdir_only => true)
      @inc_dirs  = src_directories(src_dir, @settings['ADD_INC_DIRS'].split << 'include/', :subdir_only => true)
      @inc_dirs += @src_dirs
      if @settings['EXPORTED_INC_DIRS']
        @inc_dirs  += src_directories(src_dir, @settings['EXPORTED_INC_DIRS'].split, :subdir_only => true)
      end
      @inc_dirs += lib_incs(@settings['ADD_LIBS'].split)
      @inc_dirs.uniq!

      # list of all object file directories to be created
      @obj_dirs = (@src_dirs+@test_dirs).map {|dir| dir.gsub(@src_dir, @build_dir)}
      @obj_dirs.each do |dir|
        directory dir
      end

      # fetch list of all sources with all supported source file extensions
      ignored_srcs = find_files_relative(@src_dir, @settings['IGNORED_SOURCES'].split)

      @srcs = (search_files(src_dirs, @tc.source_extensions) - ignored_srcs).uniq
      @test_srcs = search_files(test_dirs, @tc.source_extensions).uniq
      # special handling for Qt files
      if '1' == @settings['USE_QT']
        mocs = assemble_moc_file_list(search_files(src_dirs, [@tc.moc_header_extension]))
        mocs.each do |moc|
          @srcs << moc
          CLEAN.include(moc)
        end
        @srcs.uniq!
      end

      if (@settings['TEST_FRAMEWORK'].nil? or @settings['TEST_FRAMEWORK'].empty?)
        @test_fw = @tc.default_test_framework
      else
        @test_fw = @tc.test_framework(@settings['TEST_FRAMEWORK'])
      end

      @objs = @srcs.map {|file| source_to_obj(file, @src_dir, @build_dir)}
      @deps = @objs.map {|obj| obj.ext('.d')}
      if has_tests?
        @test_objs = @test_srcs.map {|file| source_to_obj(file, @src_dir, @build_dir)}
        @test_deps = @test_objs.map {|obj| obj.ext('.d')}
        load_deps(@test_deps)
        @test_inc_dirs = @settings['TEST_SOURCE_DIRS'].empty? ? '' : @test_fw.include.join(' ')
      else
        @test_objs = []
        @test_deps = []
        @test_inc_dirs = ''
      end

      # load dependency files if already generated
      load_deps(@deps)

      # all objs are dependent on project file and platform file
      (@objs+@test_objs).each do |obj|
        file obj => [@settings['PRJ_FILE'], @tc.config.platform]
      end

      @test_binary =  "#{bin_dir}/#{name}-test"

      handle_prj_type
      handle_qt if '1' == @settings['USE_QT']
      # todo check all directories for existence ?
    end


    # Check params given to #initialize
    #
    # @param [Hash] params
    # @option params [String] :name        Name of the library
    # @option params [String] :src_dir     Base source directory of lib
    # @option params [String] :bin_dir     Output binary directory of lib
    # @option params [String] :toolchain   Toolchain builder to use
    #
    def check_params(params)
      raise 'No project name given' unless params[:name]
      raise 'No settings given' unless params[:settings]
      raise 'No build directory given' unless params[:bin_dir]
      raise 'No toolchain given' unless params[:toolchain]
    end

    # Qt special handling
    def handle_qt
      unless tc.qt.check_once
        puts '### WARN: QT prerequisites not complete!'
      end
      @settings['ADD_CFLAGS'] += tc.qt.cflags
      @settings['ADD_CXXFLAGS'] += tc.qt.cflags
      @settings['ADD_LDFLAGS'] += tc.qt.ldflags
      @settings['ADD_LIBS'] += tc.qt.libs
    end

    # Settings according to project type
    def handle_prj_type
      # TODO make these settable in defaults.rb
      case @settings['PRJ_TYPE']
      when 'SOLIB'
        @binary = "#{bin_dir}/lib#{name}.so"
        @settings['ADD_CFLAGS'] += ' -fPIC -Wl,-export-dynamic'
        @settings['ADD_CXXFLAGS'] += ' -fPIC -Wl,-export-dynamic'
      when 'LIB'
        @binary = "#{bin_dir}/lib#{name}.a"
      when 'APP'
        @binary = "#{bin_dir}/#{name}"
        @app_lib = "#{build_dir}/lib#{name}-app.a"
      when 'DISABLED'
        puts "### WARNING: project #{name} is disabled !!"
      else
        raise "unsupported project type #{@settings['PRJ_TYPE']}"
      end
    end

    # Returns array of source code directories assembled via given parameters
    #
    # @param [String] main_dir                Main directory where project source is located
    # @param [Array]  sub_dirs                List of sub directories inside main_dir
    # @param [Hash]   params                  Option hash to control how directories should be added
    # @option params [Boolean]  :subdir_only  If true: only return sub directories, not main_dir in result
    #
    # @return [Array] List of sub directories assembled from each element in sub_dirs and appended to main_dir
    def src_directories(main_dir, sub_dirs, params={})
      if params[:subdir_only]
        all_dirs=[]
      else
        all_dirs = [main_dir]
      end

      sub_dirs.each do |dir|
        all_dirs << "#{main_dir}/#{dir}"
      end
      all_dirs.compact
    end


    # Returns list of include directories for name of libraries in parameter libs
    #
    # @param [Array] libs   List of library names
    #
    # @return [Array]       List of includes found for given library names
    #
    def lib_incs(libs=[])
      includes = Array.new
      libs.each do |name, param|
        lib_includes = PrjFileCache.exported_lib_incs(name)
        includes += lib_includes if lib_includes.any?
      end
      includes
    end


    # Search files recursively in directory with given extensions
    #
    # @param [Array]  directories   Array of directories to search
    # @param [Array]  extensions    Array of file extensions to use for search
    #
    # @return [Array]   list of all found files
    #
    def search_files(directories, extensions)
      extensions.each_with_object([]) do |ext, obj|
        directories.each do |dir|
          obj << FileList["#{dir}/*#{ext}"]
        end
      end.flatten.compact
    end


    # Search list of files relative to given directory
    #
    # @param [String] directory   Main directory
    # @param [Array]  files       List with Filenames
    #
    # @return [Array] List of path names of all found files
    #
    def find_files_relative(directory, files)
      return [] unless files.any?
      files.each_with_object([]) do |file, obj|
        path = "#{directory}/#{file}"
        obj << path if File.exist?(path)
      end
    end


    # Assemble list of to be generated moc files
    #
    # @param [Array] include_files  List of include files
    #
    # @return [Array]               List of to be generated moc_ files detected
    #                               via given include file list
    def assemble_moc_file_list(include_files)
      include_files.map do |file|
        "#{File.dirname(file)}/moc_#{File.basename(file).ext(@tc.moc_source)}" if fgrep(file,'Q_OBJECT')
      end.compact
    end


    # Read project file if it exists
    #
    # @param [String] file      Filename of project file
    # @return [KeyValueReader]  New KeyValueReader object with values provided via read project file
    def read_prj_settings(file)
      unless File.file?(file)
        file = File.dirname(__FILE__)+'/prj.rake'
      end
      KeyValueReader.new(file)
    end

    # Depending on the read settings we have to
    # change various values like CXXFLAGS, LDFLAGS, etc.
    def override_toolchain_vars
    end


    # Returns if any test sources found
    def has_tests?
      return @test_srcs.any?
    end

    # Loads dependency files if already generated
    #
    # @param [Array] deps   List of dependency files that have been generated via e.g. 'gcc -MM'
    def load_deps(deps)
      deps.each do |file|
        if File.file?(file)
          Rake::MakefileLoader.new.load(file)
        end
      end
    end


    # Disable a build. Is called from derived class
    # if e.g. set in prj.rake
    def disable_build
      desc '*** DISABLED ***'
      task @name => @binary
      file @binary do
      end
    end


    # Checks if projects build prerequisites are met.
    #
    # If at least one of the following criteria are met, the method returns false:
    #   * project variable PRJ_TYPE == "DISABLED"
    #   * project variable IGNORED_PLATFORMS contains build platform
    # @return   true    if project can be built on current platform
    # @return   false   if project settings prohibit building
    def project_can_build?
      (settings['PRJ_TYPE'] != 'DISABLED') and (! tc.current_platform_any?(settings['IGNORED_PLATFORMS'].split))
    end

    # Match the file stub (i.e. the filename with absolute path without extension)
    # to one of all known source (including test source) files
    #
    # @param [String] stub    A filename stub without its extension
    # @return [String]        The found source filename
    #
    # TODO optimization possible for faster lookup by using hash of source files instead of array
    def stub_to_src(stub)
      (@srcs+@test_srcs).each do |src|
        if src.ext('') == stub
          return src
        end
      end
      nil
    end

    # Transforms an object file name to its source file name by replacing
    # build directory base with the source directory base and then iterating list of
    # known sources to match
    #
    # @param [String] obj         Object filename
    # @param [String] source_dir  Project source base directory
    # @param [String] obj_dir     Project build base directory
    # @return [String]            Mapped filename
    #
    def obj_to_source(obj, source_dir, obj_dir)
      stub = obj.gsub(obj_dir, source_dir).ext('')
      src = stub_to_src(stub)
      return src if src
      raise "No matching source for #{obj} found."
    end

    # Transforms a source file name in to its object file name by replacing
    # file name extension and the source directory base with the build directory base
    #
    # @param [String] src         Source filename
    # @param [String] source_dir  Project source base directory
    # @param [String] obj_dir     Project build base directory
    # @return [String]            Mapped filename
    #
    def source_to_obj(src, source_dir, obj_dir)
      exts = '\\' + @tc.source_extensions.join('|\\')
      src.sub(/(#{exts})$/, '.o').gsub(source_dir, obj_dir)
    end

    # Transforms a source file name in to its dependency file name by replacing
    # file name extension and the source directory base with the build directory base
    #
    # @param [String] src         Source filename
    # @param [String] source_dir  Project source base directory
    # @param [String] dep_dir     Project dependency base directory
    # @return [String]            Mapped filename
    #
    def source_to_dep(src, source_dir, dep_dir)
      exts = '\\' + @tc.source_extensions.join('|\\')
      src.sub(/(#{exts})$/, '.d').gsub(source_dir, dep_dir)
    end

    # Transforms an object file into its corresponding dependency file name by replacing
    # file name extension and object directory with dependency directory
    #
    # @param [String] src         Source filename
    # @param [String] dep_dir     Project dependency base directory
    # @param [String] obj_dir     Project object base directory
    # @return [String]            Mapped filename
    #
    def obj_to_dep(src, dep_dir, obj_dir)
      src.sub(/\.o$/, '.d').gsub(dep_dir, obj_dir)
    end

    # Transforms a dependency file name into its corresponding source file name by replacing
    # file name extension and object directory with dependency directory.
    # Searches through list of source files to find it.
    #
    # @param [String] dep         Source filename
    # @param [String] source_dir  Project source base directory
    # @param [String] dep_dir     Project dependency base directory
    # @return [String]            Mapped filename
    #
    def dep_to_source(dep, source_dir, dep_dir)
      stub = dep.gsub(dep_dir, source_dir).ext('')
      src = stub_to_src(stub)
      return src if src
      raise "No matching source for #{dep} found."
    end

    # Create build rules for generating an object. Dependency to corresponding source file is made via proc
    # object
    def create_build_rules
      platform_flags_fixup(search_libs(@settings))

      incs = inc_dirs
      # map object to source file and make it dependent on creation of all object directories
      rule /#{build_dir}\/.*\.o/ => [ proc {|tn| obj_to_source(tn, src_dir, build_dir)}] + obj_dirs do |t|
        if t.name =~ /\/tests\//
          # test framework additions
          incs << @test_inc_dirs unless incs.include?(@test_inc_dirs)
          @settings['ADD_CXXFLAGS'] += @test_fw.cflags
          @settings['ADD_CFLAGS'] += @test_fw.cflags
        end

        tc.obj(:source => t.source,
               :object => t.name,
               :settings => @settings,
               :includes => incs.uniq)
      end

      # map dependency to source file and make it dependent on creation of all object directories
      rule /#{build_dir}\/.*\.d/ => [ proc {|tn| dep_to_source(tn, src_dir, build_dir)}] + obj_dirs do |t|
        # don't generate dependencies for assembler files XXX DS: use tc.file_extensions[:as_sources]
        if (t.source.end_with?('.S') || t.source.end_with?('.s'))
          tc.touch(t.name)
          next
        end

        if t.name =~ /\/tests\//
          # test framework additions
          incs << @test_inc_dirs unless incs.include?(@test_inc_dirs)
          @settings['ADD_CXXFLAGS'] += @test_fw.cflags
          @settings['ADD_CFLAGS'] += @test_fw.cflags
        end

        tc.dep(:source => t.source,
               :dep => t.name,
               :settings => @settings,
               :includes => incs.uniq)
      end

      # make moc source file dependent on corresponding header file, XXX DS: only if project uses QT
      rule /#{src_dir}\/.*moc_.*#{Regexp.escape(tc.moc_source)}$/ => [ proc {|tn| tn.gsub(/moc_/, '').ext(tc.moc_header_extension) } ] do |t|
        tc.moc(:source => t.source,
               :moc => t.name,
               :settings => @settings)
      end
    end

    # Change ADD_CFLAGS, ADD_CXXFLAGS, ADD_LDFLAGS according to settings in platform file.
    #
    # @param libs [Array]   Array of libraries to be considered
    #
    def platform_flags_fixup(libs)
      libs[:all].each do |lib|
        ps = tc.platform_settings_for(lib)
        unless ps.empty?
          @settings['ADD_CFLAGS'] += " #{ps[:CFLAGS]}" if ps[:CFLAGS]
          @settings['ADD_CXXFLAGS'] += " #{ps[:CXXFLAGS]}" if ps[:CXXFLAGS]

          # remove all -lXX settings from ps[:LDFLAGS] and use rest for @settings['ADD_LDFLAGS'],
          # -lXX is set in Toolchain#linker_line_for
          @settings['ADD_LDFLAGS'] += ps[:LDFLAGS].gsub(/(\s|^)+-l\S+/, '') if ps[:LDFLAGS]
        end
      end
    end

    # Search dependent libraries as specified in ADD_LIBS setting
    # of prj.rake file
    #
    # @param [String] settings    The project settings definition
    #
    # @return [Hash]                        Containing the following components mapped to an array:
    # @option return [Array] :local         all local libs found by toolchain
    # @option return [Array] :local_alibs   local static libs found by toolchain
    # @option return [Array] :local_solibs  local shared libs found by toolchain
    # @option return [Array] :all           local + external libs
    #
    def search_libs(settings)
      # get all libs specified in ADD_LIBS
      search_libs =  settings['ADD_LIBS'].split
      our_lib_deps = []
      search_libs.each do |lib|
        our_lib_deps << lib
        deps_of_lib = @@all_libs_and_deps[lib]
        if deps_of_lib
          our_lib_deps += deps_of_lib
        end
      end
      our_lib_deps.uniq!

      # match libs found by toolchain
      solibs_local = []
      alibs_local = []
      our_lib_deps.each do |lib|
        if PrjFileCache.contain?('LIB', lib)
          alibs_local << lib
        elsif PrjFileCache.contain?('SOLIB', lib)
          solibs_local << lib
        end
      end
      local_libs = (alibs_local + solibs_local) || []

      # return value is a hash
      {
        :local        => local_libs,
        :local_alibs  => alibs_local,
        :local_solibs => solibs_local,
        :all          => our_lib_deps
      }
    end


    # Iterate over each local library and execute given block
    #
    # @param [Block]  block   The block that is executed
    #
    def each_local_lib(&block)
      libs = search_libs(@settings)
      libs[:local].each do |lib|
        yield(lib)
      end
    end


    #
    # Returns absolute paths to given libraries, if they are local libraries
    # of the current project.
    #
    def paths_of_libs(some_libs)
      local_libs = Array.new

      some_libs.each do |lib|
        if PrjFileCache.contain?('LIB', lib)
          local_libs << "#{tc.settings['LIB_OUT']}/lib#{lib}.a"
        elsif PrjFileCache.contain?('SOLIB', lib)
          local_libs << "#{tc.settings['LIB_OUT']}/lib#{lib}.so"
        end
      end

      local_libs
    end
    #
    # Returns absolute paths to dependend local libraries, i.e. libraries
    # of the current project.
    #
    def paths_of_local_libs
      local_libs = Array.new

      each_local_lib() do |lib|
        if PrjFileCache.contain?('LIB', lib)
          local_libs << "#{tc.settings['LIB_OUT']}/lib#{lib}.a"
        elsif PrjFileCache.contain?('SOLIB', lib)
          local_libs << "#{tc.settings['LIB_OUT']}/lib#{lib}.so"
        end
      end

      local_libs
    end

    # Greps for a string in a file
    #
    # @param [String] file    Filename to be used for operation
    # @param [String] string  String to be searched for in file
    #
    # @return [boolean]  true if string found inside file, false otherwise
    #
    def fgrep(file, string)
      open(file).grep(/#{string}/).any?
    end
  end
end
