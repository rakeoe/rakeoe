# -*- ruby -*-

require 'rbconfig'
require 'rake/loaders/makefile'
require 'rakeoe/defaults'
require 'rakeoe/test_framework'

module RakeOE

#
# Toolchain specific key value reader
#
# @author Daniel Schnell
class Toolchain
  attr_reader  :qt, :settings, :target, :config

  # Initializes object
  #
  # @param  [RakeOE::Config] config     Project wide configurations
  #
  def initialize(config)
    raise 'Configuration failure' unless config.checks_pass?

    @config = config

    begin
      @kvr = KeyValueReader.new(config.platform)
    rescue Exception => e
      puts e.message
      raise
    end

    @settings = @kvr.env
    fixup_env

    # save target platform of our compiler (gcc specific)
    if RbConfig::CONFIG["host_os"] != "mingw32"
      @target=`export PATH=#{@settings['PATH']} && #{@settings['CC']} -dumpmachine`.chop
    else
      @target=`PATH = #{@settings['PATH']} & #{@settings['CC']} -dumpmachine`.chop
    end

    @settings['TOUCH'] = 'touch'
    # XXX DS: we should only instantiate @qt if we have any qt settings
    @qt = QtSettings.new(self)
    set_build_vars()

    init_test_frameworks
    sanity
  end


  # Do some sanity checks
  def sanity
    # TODO DS: check if libs and apps directories exist
    # TODO DS: check if test frameworks exist
    # check if target is valid

    if @settings['CC'].empty?
      raise "No Compiler specified. Either add platform configuration via RakeOE::Config object in Rakefile or use TOOLCHAIN_ENV environment variable"
    end

    if @target.nil? || @target.empty?
      raise "Compiler #{@settings['CC']} does not work. Fix platform settings or use TOOLCHAIN_ENV environment variable "
    end

  end

  # returns the build directory
  def build_dir
    "#{@config.directories[:build]}/#{@target}/#{@config.release}"
  end


  # Initializes definitions for test framework
  # TODO: Add possibility to configure test framework specific CFLAGS/CXXFLAGS
  def init_test_frameworks()
    @@test_framework ||= Hash.new

    config_empty_test_framework

    if @config.test_fw.size > 0
      if PrjFileCache.contain?('LIB', @config.test_fw)
        @@test_framework[@config.test_fw] = TestFramework.new(:name         => @config.test_fw,
                                                              :binary_path  => "#{@settings['LIB_OUT']}/lib#{@config.test_fw}.a",
                                                              :include_dir  => PrjFileCache.exported_lib_incs(@config.test_fw),
                                                              :cflags       => '')
      else
          puts "WARNING: Configured test framework (#{@config.test_fw}) does not exist in project!"
      end
    end
  end

  # Configures empty test framework
  def config_empty_test_framework
    @@test_framework[''] = TestFramework.new(:name         => '',
                                             :binary_path  => '',
                                             :include_dir  => '',
                                             :cflags       => '')

  end

  # Returns default test framework or nil if none defined
  def default_test_framework
    test_framework(@config.test_fw) || test_framework('')
  end

  # Returns definitions of specific test framework or none if
  # specified test framework doesn't exist
  def test_framework(name)
    @@test_framework[name]
  end

  # Returns list of all registered test framework names
  def test_frameworks
    @@test_framework.keys
  end

  # returns library project setting
  def lib_setting(name, setting)
    @libs.get(name, setting)
  end

  # returns app project setting
  def app_setting(name, setting)
    @apps.get(name, setting)
  end

  # returns c++ source extensions
  def cpp_source_extensions
    (@config.suffixes[:cplus_sources] + [@config.suffixes[:moc_source]]).uniq
  end

  # returns c source extensions
  def c_source_extensions
    @config.suffixes[:c_sources].uniq
  end

  # returns assembler source extensions
  def as_source_extensions
    @config.suffixes[:as_sources].uniq
  end

  # returns all source extensions
  def source_extensions
    cpp_source_extensions + c_source_extensions + as_source_extensions
  end

  # returns c++ header extensions
  def cpp_header_extensions
    (@config.suffixes[:cplus_headers] + [@config.suffixes[:moc_header]]).uniq
  end

  # returns c header extensions
  def c_header_extensions
    @config.suffixes[:c_headers].uniq
  end

  # returns moc header extensions
  def moc_header_extension
    @config.suffixes[:moc_header]
  end

  # returns c++ header extensions
  def moc_source
    @config.suffixes[:moc_source]
  end

  # Specific fixups for toolchain
  def fixup_env
    # set system PATH if no PATH defined
    @settings['PATH'] ||= ENV['PATH']

    # replace $PATH
    @settings['PATH'] = @settings['PATH'].gsub('$PATH', ENV['PATH'])

    # create ARCH
    @settings['ARCH'] = "#{@settings['TARGET_PREFIX']}".chop

    # remove optimizations, we set these explicitly
    @settings['CXXFLAGS'] = "#{@settings['CXXFLAGS']} -DPROGRAM_VERSION=\\\"#{@config.sw_version}\\\"".gsub('-O2', '')
    @settings['CFLAGS'] = "#{@settings['CFLAGS']} -DPROGRAM_VERSION=\\\"#{@config.sw_version}\\\"".gsub('-O2', '')
    KeyValueReader.substitute_dollar_symbols!(@settings)
  end


  # Set common build variables
  #
  def set_build_vars
    warning_flags = ' -W -Wall'
    if 'release' == @config.release
      optimization_flags = " #{@config.optimization_release} -DRELEASE"
    else
      optimization_flags = " #{@config.optimization_dbg} -g"
    end

    # we could make these also arrays of source directories ...
    @settings['APP_SRC_DIR'] = 'src/app'
    @settings['LIB_SRC_DIR'] = 'src/lib'

    # derived settings
    @settings['BUILD_DIR'] = "#{build_dir}"
    @settings['LIB_OUT'] = "#{@settings['BUILD_DIR']}/libs"
    @settings['APP_OUT'] = "#{@settings['BUILD_DIR']}/apps"
    unless @settings['OECORE_TARGET_SYSROOT'].nil? || @settings['OECORE_TARGET_SYSROOT'].empty?
      @settings['SYS_LFLAGS'] = "-L#{@settings['OECORE_TARGET_SYSROOT']}/lib -L#{@settings['OECORE_TARGET_SYSROOT']}/usr/lib"
    end

    # set LD_LIBRARY_PATH
    @settings['LD_LIBRARY_PATH'] = @settings['LIB_OUT']

    # standard settings
    @settings['CXXFLAGS'] += warning_flags + optimization_flags + " #{@config.language_std_cpp}"
    @settings['CFLAGS'] += warning_flags + optimization_flags + " #{@config.language_std_c}"
    if @settings['PRJ_TYPE'] == 'SOLIB'
      @settings['CXXFLAGS'] += ' -fPIC'
      @settings['CFLAGS'] += ' -fPIC'
    end
    # !! don't change order of the following string components without care !!
    @settings['LDFLAGS'] = @settings['LDFLAGS'] + " -L #{@settings['LIB_OUT']} #{@settings['SYS_LFLAGS']} -Wl,--no-as-needed -Wl,--start-group"
  end

  # Executes the command
  def sh(cmd, silent = false)

    if RbConfig::CONFIG["host_os"] != "mingw32"
      full_cmd = "export PATH=#{@settings['PATH']} && #{cmd}"
    else
      full_cmd = "PATH = #{@settings['PATH']} & #{cmd}"
    end

    if silent
      system full_cmd
    else
      Rake::sh full_cmd
    end
  end


  # Removes list of given files
  # @param [String]  files   List of files to be deleted
  def rm(files)
    if files
      Rake::sh "rm -f #{files}" unless files.empty?
    end
  end


  # Executes a given binary
  #
  # @param [String] binary    Absolute path of the binary to be executed
  #
  def run(binary)
    # compare ruby platform config and our target setting
    if @target[RbConfig::CONFIG["target_cpu"]]
      system "export LD_LIBRARY_PATH=#{@settings['LD_LIBRARY_PATH']} && #{binary}"
    else
      puts "Warning: Can't execute on this platform: #{binary}"
    end
  end

  # Executes a given test binary with test runner specific parameter(s)
  #
  # @param [String] binary    Absolute path of the binary to be executed
  #
  def run_junit_test(binary)
    # compare ruby platform config and our target setting
    if @target[RbConfig::CONFIG["target_cpu"]]
      system "export LD_LIBRARY_PATH=#{@settings['LD_LIBRARY_PATH']} && #{binary} -o junit"
    else
      puts "Warning: Can't execute test on this platform: #{binary}"
    end
  end

  # Tests given list of platforms if any of those matches the current platform
  def current_platform_any?(platforms)
    ([@target] & platforms).any?
  end

  # Generates compiler include line from given include path list
  #
  # @param [Array]  paths   Paths to be used for include file search
  #
  # @return [String]        Compiler include line
  #
  def compiler_incs_for(paths)
    paths.each_with_object('') {|path, str| str << " -I#{path}"}
  end

  # Generates linker line from given library list.
  # The linker line normally will be like -l<lib1> -l<lib2>, ...
  #
  # If a library has specific platform specific setting in the platform file
  # with a specific -l<lib> alternative, this will be used instead.
  #
  # @param [Array]  libs  Libraries to be used for linker line
  #
  # @return [String]      Linker line
  #
  def linker_line_for(libs)
    return '' if (libs.nil? || libs.empty?)

    libs.map do |lib|
      settings = platform_settings_for(lib)
      if settings[:LDFLAGS].nil? || settings[:LDFLAGS].empty?
        # automatic linker line if no platform specific LDFLAGS exist
        "-l#{lib}"
      else
        # only matches -l<libname> settings
        /(\s|^)+-l\S+/.match(settings[:LDFLAGS]).to_s
      end
    end.join(' ').strip
  end


  # Reduces the given list of libraries to bare minimum, i.e.
  # the minimum needed for actual platform
  #
  # @libs   list of libraries
  #
  # @return reduced list of libraries
  #
  def reduce_libs_to_bare_minimum(libs)
    rv = libs.clone
    lib_entries = RakeOE::PrjFileCache.get_lib_entries(libs)
    lib_entries.each_pair do |lib, entry|
      rv.delete(lib) unless RakeOE::PrjFileCache.project_entry_buildable?(entry, @target)
    end
    rv
  end


  # Return array of library prerequisites for given file
  def libs_for_binary(a_binary, visited=[])
    return [] if visited.include?(a_binary)
    visited << a_binary
    pre = Rake::Task[a_binary].prerequisites
    rv = []
    pre.each do |p|

      next if (File.extname(p) != '.a') && (File.extname(p) != '.so')
      next if p =~ /\-app\.a/

      rv << File.basename(p).gsub(/(\.a|\.so|^lib)/, '')
      rv += libs_for_binary(p, visited)   # Recursive call
    end

    reduce_libs_to_bare_minimum(rv.uniq)
  end

  # Touches a file
  def touch(file)
    sh "#{@settings['TOUCH']} #{file}"
  end


  # Tests if all given files in given list exist
  # @return true    all file exist
  # @return false   not all file exist
  def test_all_files_exist?(files)
    files.each do |file|
      raise "No such file: #{file}" unless File.exist?(file)
    end
  end

  def diagnose_buildability(projects)
    projects.each do |project|

      RakeOE::PrjFileCache.project_entry_buildable?(entry, platform)
    end

  end


  # Returns platform specific settings of a resource (APP/LIB/SOLIB or external resource like e.g. an external library)
  # as a hash with the keys CFLAGS, CXXFLAGS and LDFLAGS. The values are empty if no such resource settings exist inside
  # the platform file. The resulting hash values can be used for platform specific compilation/linkage against the
  # the resource.
  #
  # @param resource_name  [String]  name of resource
  # @return [Hash]                  Hash of compilation/linkage flags or empty hash if no settings are defined
  #                                 The returned hash has the following format:
  #                                 { :CFLAGS => '...', :CXXFLAGS => '...', :LDFLAGS => '...'}
  #
  def platform_settings_for(resource_name)
    return {} if resource_name.empty?

    rv = Hash.new
    rv[:CFLAGS]  = @settings["#{resource_name}_CFLAGS"]
    rv[:CXXFLAGS]= @settings["#{resource_name}_CXXFLAGS"]
    rv[:LDFLAGS] = @settings["#{resource_name}_LDFLAGS"]
    rv = {} if rv.values.empty?
    rv
  end

  # Creates compilation object
  #
  # @param  [Hash] params
  # @option params [String] :source   source filename with path
  # @option params [String] :object   object filename path
  # @option params [Hash]   :settings project specific settings
  # @option params [Array]  :includes include paths used
  #
  def obj(params = {})
    extension = File.extname(params[:source])
    object    = params[:object]
    source    = params[:source]
    incs      = compiler_incs_for(params[:includes]) + " #{@settings['LIB_INC']}"

    case
      when cpp_source_extensions.include?(extension)
        flags = @settings['CXXFLAGS'] + ' ' + params[:settings]['ADD_CXXFLAGS']
        compiler = "#{@settings['CXX']} -x c++ "
      when c_source_extensions.include?(extension)
        flags = @settings['CFLAGS'] + ' ' + params[:settings]['ADD_CFLAGS']
        compiler = "#{@settings['CC']} -x c "
      when as_source_extensions.include?(extension)
        flags = ''
        compiler = "#{@settings['AS']}"
      else
        raise "unsupported source file extension (#{extension}) for creating object!"
    end
    sh "#{compiler} #{flags} #{incs} -c #{source} -o #{object}"
  end


  # Creates dependency
  #
  # @param  [Hash] params
  # @option params [String] :source   source filename with path
  # @option params [String] :dep      dependency filename path
  # @option params [Hash]   :settings project specific settings
  # @option params [Array]  :includes include paths used
  #
  def dep(params = {})
    extension = File.extname(params[:source])
    dep       = params[:dep]
    source    = params[:source]
    incs      = compiler_incs_for(params[:includes]) + " #{@settings['LIB_INC']}"
    case
      when cpp_source_extensions.include?(extension)
        flags = @settings['CXXFLAGS'] + ' ' + params[:settings]['ADD_CXXFLAGS']
        compiler = "#{@settings['CXX']} -x c++ "
      when c_source_extensions.include?(extension)
        flags  = @settings['CFLAGS'] + ' ' + params[:settings]['ADD_CFLAGS']
        compiler = "#{@settings['CC']} -x c "
      when as_source_extensions.include?(extension)
        flags = ''
        compiler = "#{@settings['AS']}"
      else
        raise "unsupported source file extension (#{extension}) for creating dependency!"
    end
    sh "#{compiler} -MM #{flags} #{incs} -c #{source} -MT #{dep.ext('.o')} -MF #{dep}", silent: true
  end


  # Creates moc_ source file
  #
  # @param  [Hash] params
  # @option params [String] :source   source filename with path
  # @option params [String] :moc      moc_XXX filename path
  # @option params [Hash]   :settings project specific settings
  #
  def moc(params = {})
    moc_compiler = @settings['OE_QMAKE_MOC']
    raise 'No Qt Toolchain set' if moc_compiler.empty?
    sh "#{moc_compiler} -i -f#{File.basename(params[:source])} #{params[:source]} >#{params[:moc]}"
  end


  # Creates library
  #
  # @param  [Hash] params
  # @option params [Array]  :objects  object filename paths
  # @option params [String] :lib      library filename path
  # @option params [Hash]   :settings project specific settings
  #
  def lib(params = {})
    ldflags   = params[:settings]['ADD_LDFLAGS'] + ' ' + @settings['LDFLAGS']
    objs      = params[:objects].join(' ')
    dep_libs = (params[:libs] + libs_for_binary(params[:lib])).uniq
    libs      = linker_line_for(dep_libs)
    extension = File.extname(params[:lib])

    case extension
      when ('.a')
        # need to use 'touch' for correct timestamp, ar doesn't update the timestamp
        # if archive hasn't changed
        sh "#{@settings['AR']} curv #{params[:lib]} #{objs} && #{@settings['TOUCH']} #{params[:lib]}"
      when '.so'
        sh "#{@settings['CXX']} -shared  #{ldflags} #{libs} #{objs} -o #{params[:lib]}"
      else
        raise "unsupported library extension (#{extension})!"
    end
  end


  # Creates application
  #
  # @param  [Hash] params
  # @option params [Array]  :objects  array of object file paths
  # @option params [Array]  :libs     array of libraries that should be linked against
  # @option params [String] :app      application filename path
  # @option params [Hash]   :settings project specific settings
  # @option params [Array]  :includes include paths used
  #
  def app(params = {})
    incs    = compiler_incs_for(params[:includes])
    ldflags = params[:settings]['ADD_LDFLAGS'] + ' ' + @settings['LDFLAGS']
    objs    = params[:objects].join(' ')
    dep_libs = (params[:libs] + libs_for_binary(params[:app])).uniq
    libs    = linker_line_for(dep_libs)

    sh "#{@settings['SIZE']} #{objs} >#{params[:app]}.size" if @settings['SIZE']
    sh "#{@settings['CXX']} #{incs} #{objs} #{ldflags} #{libs} -o #{params[:app]} -Wl,-Map,#{params[:app]}.map"
    sh "#{@settings['OBJCOPY']} -O binary #{params[:app]} #{params[:app]}.bin"
  end

  # Creates test
  #
  # @param  [Hash] params
  # @option params [Array]  :objects   array of object file paths
  # @option params [Array]  :libs      array of libraries that should be linked against
  # @option params [String] :framework test framework name
  # @option params [String] :test      test filename path
  # @option params [Hash]   :settings  project specific settings
  # @option params [Array]  :includes  include paths used
  #
  def test(params = {})
    incs    = compiler_incs_for(params[:includes])
    ldflags = params[:settings]['ADD_LDFLAGS'] + ' ' +  @settings['LDFLAGS']
    objs    = params[:objects].join(' ')
    test_fw = linker_line_for([params[:framework]])
    dep_libs = (params[:libs] + libs_for_binary(params[:test])).uniq
    libs    = linker_line_for(dep_libs)

    sh "#{@settings['CXX']} #{incs} #{objs} #{test_fw} #{ldflags} #{libs} -o #{params[:test]}"
  end

  def dump
    puts '**************************'
    puts '* Platform configuration *'
    puts '**************************'
    @kvr.dump
  end

end

end
