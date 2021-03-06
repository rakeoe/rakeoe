# -*- ruby -*-
require 'rakeoe/defaults'

module RakeOE

  # Project wide configurations
  # RakeOE::init() takes a RakeOE::Config object. Therefore this class should be used from inside the project Rakefile
  # to change project wide settings before calling RakeOE::init().
  class Config

    attr_accessor :suffixes, :directories, :platform , :release, :test_fw, :optimization_dbg, :optimization_release,
                  :language_std_c, :language_std_cpp, :sw_version, :stripped, :generate_hex, :generate_bin, :generate_map

    def initialize

      # Common file suffixes used for C/C++/Assembler files inside the project.
      # This is a hash object with the following key => value mappings (examples):
      # {
      #     :as_sources => %w[.s],                      Assembler source
      #     :c_sources => %w[.c],                       C source
      #     :c_headers => %w[.h],                       C headers
      #     :cplus_sources => %w[.cpp .cc],             C++ sources
      #     :cplus_headers => %w[.h .hpp],              C++ headers
      #     :moc_header => '.h',                        Qt MOC file header
      #     :moc_source => '.cpp'                       Qt MOC file source
      # }
      @suffixes=RakeOE::Default.suffixes
      
      # Directories used for the project
      # This is a hash object with the following key => value mappings (examples):
      # {
      #     :apps => %w[src/app],                       Application top level directories
      #     :libs => %w[src/lib1 src/lib2],             Library top level directories
      #     :build => 'build'                           Build top level directory
      # }
      @directories=RakeOE::Default.dirs

      # Platform configuration used for the project
      # This is the absolute path to the platform definition file
      #
      # This parameter can be overridden via environment variable TOOLCHAIN_ENV
      @platform = ENV['TOOLCHAIN_ENV'].nil? ? '' : ENV['TOOLCHAIN_ENV']

      # Release mode used for the project
      # It can take the values "dbg" or "release" and influences the build behaviour.
      # When "dbg", optimization definitions set via @optimization_dbg are used.
      # When "release", optimization definitions set via @optimization_release are used.
      # CFLAGS/CXXFLAGS will contain the symbol -DRELEASE
      #
      # This parameter can be overridden via environment variable RELEASE. If the latter
      # is defined, this configuration variable has the value "release"
      @release = ENV['RELEASE'].nil? ? RakeOE::Default.release : 'release'

      # Test framework used for linking test case binaries
      # This takes the name of the test framework that has to be integrated into the project
      # library path.
      # RakeOE does not require a specific test framework, but CppUTest and CUnit are proposals
      # that have been tested to work fine.
      @test_fw=RakeOE::Default.test_fw

      # Optimization levels used for compiling binaries (e.g. -O0, -O1, -O2, -O3, -Og).
      # Depending on the release mode, either @optimization_dbg or @optimization_release
      # is used
      @optimization_dbg=RakeOE::Default.optimization_dbg
      @optimization_release=RakeOE::Default.optimization_release

      # Language standard (e.g. -std=gnu99, -std=c++03, -std=c99, etc. )
      @language_std_c=RakeOE::Default.lang_std_c
      @language_std_cpp=RakeOE::Default.lang_std_cpp

      # Software version string
      #
      # This parameter can be overridden via environment variable SW_VERSION_ENV.
      @sw_version = ENV['SW_VERSION_ENV'].nil? ? "#{RakeOE::Default.sw_version}-#{@release}" : ENV['SW_VERSION_ENV']

      # Stripped flag
      @stripped = RakeOE::Default.stripped

      # Hex file flag. Generates a binary.hex file for each app binary if flag is set
      @generate_hex = RakeOE::Default.generate_hex

      # Bin file flag. Generates a binary.bin file for each app binary if flag is set
      @generate_bin = RakeOE::Default.generate_bin

      # Map file flag. Generates a map file file for each app/lib/solib binary if flag is set
      @generate_map = RakeOE::Default.generate_map

      # Project settings as specified in prj.rake file
      @prj_settings = RakeOE::Default.prj_settings
    end


    # Checks configuration, e.g. if given files do exist or if vital configuration settings are missing
    #
    # @return [bool]    true if checks pass, false otherwise
    #
    def checks_pass?
      rv = true
      unless File.exist?(@platform)
        puts "No platform or invalid platform configuration given: (#{@platform}) !"
        puts "Use either property 'platform' via RakeOE::Config object in the Rakefile or environment variable TOOLCHAIN_ENV"
        rv = false
      end
      rv
    end


    # Dumps configuration to stdout
    def dump
      puts '******************'
      puts '* RakeOE::Config *'
      puts '******************'
      puts "Directories                 : #{@directories}"
      puts "Suffixes                    : #{@suffixes}"
      puts "Platform                    : #{@platform}"
      puts "Release mode                : #{@release}"
      puts "Test framework              : #{@test_fw}"
      puts "Optimization dbg            : #{@optimization_dbg}"
      puts "Optimization release        : #{@optimization_release}"
      puts "Language Standard for C     : #{@language_std_c}"
      puts "Language Standard for C++   : #{@language_std_cpp}"
      puts "Software version string     : #{@sw_version}"
      puts "Generate bin file           : #{@generate_bin}"
      puts "Generate hex file           : #{@generate_hex}"
      puts "Generate map file           : #{@generate_map}"
      puts "Strip objects               : #{@stripped}"
    end
  end
end

