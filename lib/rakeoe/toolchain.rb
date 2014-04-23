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
  attr_reader  :qt, :settings, :target

  # Initializes object
  #
  # @param  [Hash] params
  # @option params [String] :platform         path to the platform build settings file
  # @option params [String] :release          either of 'release' or 'dbg'
  # @option params [Hash]   :directories      directories where all sources and builds should be located
  # @option params [Hash]   :file_extensions  hash of source code file extension mappings
  #                                           e.g. { cplus_sources:  ['cpp', 'cxx', 'C'] }
  def initialize(params = {
                            :platform => DEFAULT_PLATFORM,
                            :release => DEFAULT_RELEASE,
                            :directories => DEFAULT_DIRS,
                            :file_extensions => DEFAULT_EXTENSIONS
                          })

    @dirs = params[:directories]
    @file_extensions = params[:file_extensions] || DEFAULT_EXTENSIONS
    @sw_version = params[:sw_version] || 'unversioned'
    platform_file = params[:platform]
    platform_file = DEFAULT_PLATFORM if (platform_file.nil? or platform_file.empty?)

    @kvr = KeyValueReader.new(platform_file)
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
    set_build_vars(params[:release])

    init_test_frameworks
    sanity
  end


  # Do some sanity checks
  def sanity
    raise 'No directory parameters given' if @dirs.nil?

    # TODO DS: check if libs and apps directories exist
    # TODO DS: check if test frameworks exist
  end

  # returns the build directory
  def build_dir
    @dirs[:build]
  end


  # Initializes list of known test frameworks.
  def init_test_frameworks()
    @@test_framework ||= Hash.new

    # XXX DS: Too much information about test frameworks ...
    if PrjFileCache.contain?('LIB', 'CUnit')
      @@test_framework['CUnit'] = TestFramework.new(:name         => 'CUnit',
                                                    :binary_path  => "#{@settings['LIB_OUT']}/libCUnit.a",
                                                    :include_dir  => PrjFileCache.get('LIB', 'CUnit', 'PRJ_HOME') + '/CUnit/Headers',
                                                    :cflags       => '')
    end

    if PrjFileCache.contain?('LIB', 'CppUTest')
      @@test_framework['CppUTest'] = TestFramework.new(:name         => 'CppUTest',
                                                       :binary_path  => "#{@settings['LIB_OUT']}/libCppUTest.a",
                                                       :include_dir  => PrjFileCache.get('LIB', 'CppUTest', 'PRJ_HOME') + '/include',
                                                       :cflags       => ' -DCPPUTEST_USE_MEM_LEAK_DETECTION=N ')
    end
  end

  # Returns default test framework
  def default_test_framework
    test_framework(DEFAULT_TEST_FW)
  end

  # Returns definitions of specific test framework
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
    (@file_extensions[:cplus_sources] + [@file_extensions[:moc_source]]).uniq
  end

  # returns c source extensions
  def c_source_extensions
    @file_extensions[:c_sources].uniq
  end

  # returns assembler source extensions
  def as_source_extensions
    @file_extensions[:as_sources].uniq
  end

  # returns all source extensions
  def source_extensions
    cpp_source_extensions + c_source_extensions + as_source_extensions
  end

  # returns c++ header extensions
  def cpp_header_extensions
    (@file_extensions[:cplus_headers] + [@file_extensions[:moc_header]]).uniq
  end

  # returns c header extensions
  def c_header_extensions
    @file_extensions[:c_headers].uniq
  end

  # returns moc header extensions
  def moc_header_extension
    @file_extensions[:moc_header]
  end

  # returns c++ header extensions
  def moc_source
    @file_extensions[:moc_source]
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
    @settings['CXXFLAGS'] = "#{@settings['CXXFLAGS']} -DPROGRAM_VERSION=\\\"#{@sw_version}\\\"".gsub('-O2', '')
    @settings['CFLAGS'] = "#{@settings['CFLAGS']} -DPROGRAM_VERSION=\\\"#{@sw_version}\\\"".gsub('-O2', '')
    KeyValueReader.substitute_dollar_symbols!(@settings)
  end


  # Set common build variables
  #
  # @param [String] release_mode   Release mode used for the build, either 'release' or 'dbg'
  def set_build_vars(release_mode)
    warning_flags = ' -W -Wall'
    if 'release' == release_mode
      optimization_flags = " #{DEFAULT_OPTIMIZATION_RELEASE} -DRELEASE"
    else
      optimization_flags = " #{DEFAULT_OPTIMIZATION_DEBUG} -g"
    end

    # we could make these also arrays of source directories ...
    @settings['APP_SRC_DIR'] = 'src/app'
    @settings['LIB_SRC_DIR'] = 'src/lib'

    # derived settings
    @settings['BUILD_DIR'] = "#{build_dir}/#{@target}/#{release_mode}"
    @settings['LIB_OUT'] = "#{@settings['BUILD_DIR']}/libs"
    @settings['APP_OUT'] = "#{@settings['BUILD_DIR']}/apps"
    @settings['SYS_LFLAGS'] = "-L#{@settings['OECORE_TARGET_SYSROOT']}/lib -L#{@settings['OECORE_TARGET_SYSROOT']}/usr/lib"

    # set LD_LIBRARY_PATH
    @settings['LD_LIBRARY_PATH'] = @settings['LIB_OUT']

    # standard settings
    @settings['CXXFLAGS'] += warning_flags + optimization_flags + " #{DEFAULT_LANGUAGE_STANDARD_CPP}"
    @settings['CFLAGS'] += warning_flags + optimization_flags + " #{DEFAULT_LANGUAGE_STANDARD_C}"
    if @settings['PRJ_TYPE'] == 'SOLIB'
      @settings['CXXFLAGS'] += ' -fPIC'
      @settings['CFLAGS'] += ' -fPIC'
    end
    # !! don't change order of the following string components without care !!
    @settings['LDFLAGS'] = @settings['LDFLAGS'] + " -L #{@settings['LIB_OUT']} #{@settings['SYS_LFLAGS']} -Wl,--no-as-needed -Wl,--start-group"
  end

  # Executes the command
  def sh(cmd, silent: false)
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

  # Generates linker line from given library list
  #
  # @param [Array]  libs  Libraries to be used for linker line
  #
  # @return [String]      Linker line
  #
  def linker_line_for(libs)
    libs.map { |lib| "-l#{lib}" }.join(' ').strip
  end

  # Touches a file
  def touch(file)
    sh "#{@settings['TOUCH']} #{file}"
  end

  # Returns platform specific settings of a resource (APP/LIB/SOLIB or external resource like e.g. an external library)
  # as a hash with the keys CFLAGS, CXXFLAGS and LDFLAGS. The values are empty if no such resource settings exist inside
  # the platform file. The resulting hash values can be used for platform specific compilation/linkage against the
  # the resource.
  #
  # @param resource_name  [String]  name of resource
  # @return [Hash]                  Hash of compilation/linkage flags or empty hash if no settings are defined
  #                                 The returned hash has the following format:
  #                                 { 'CFLAGS' => '...', 'CXXFLAGS' => '...', 'LDFLAGS' => '...'}
  #
  def res_platform_settings(resource_name)
    return {} if resource_name.empty?

    rv = Hash.new
    rv['CFLAGS'] = @settings["#{resource_name}_CFLAGS"]
    rv['CXXFLAGS'] = @settings["#{resource_name}_CXXFLAGS"]
    rv['LDFLAGS'] = @settings["#{resource_name}_LDFLAGS"]
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
=begin
puts
puts "incs for #{object}: #{incs}"
puts
puts "params[:includes]:#{params[:includes]}"
puts
=end
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
    ldflags   = params[:settings]['ADD_LDFLAGS']
    objs      = params[:objects].join(' ')
    extension = File.extname(params[:lib])

    case extension
      when ('.a')
        # need to use 'touch' for correct timestamp, ar doesn't update the timestamp
        # if archive hasn't changed
        sh "#{@settings['AR']} curv #{params[:lib]} #{objs} && #{@settings['TOUCH']} #{params[:lib]}"
      when '.so'
        sh "#{@settings['CXX']} -shared  #{ldflags} #{objs} -o #{params[:lib]}"
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
    libs    = linker_line_for(params[:libs])

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
    libs    = linker_line_for(params[:libs])

    sh "#{@settings['CXX']} #{incs} #{objs} #{test_fw} #{ldflags} #{libs} -o #{params[:test]}"
  end

end

end
