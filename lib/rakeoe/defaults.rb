# -*- ruby -*-

module RakeOE
  # Project wide defaults that will be used for configuration. Configuration can be overridden via Rakefile.

  # A list of default file extensions used for the project.
  # This has to match the format as described for RakeOE::Config.suffixes
  DEFAULT_SUFFIXES = {
    :as_sources => %w[.S .s],
    :c_sources => %w[.c],
    :c_headers => %w[.h],
    :cplus_sources => %w[.cpp .cxx .C .cc],
    :cplus_headers => %w[.h .hpp .hxx .hh],
    :moc_header => '.h',
    :moc_source => '.cpp'
  }

  # A list of default directories used for the project
  DEFAULT_DIRS = {
    :apps => %w[src/app],
    :libs => %w[src/lib src/3rdparty],
    :build => 'build',
    :deploy => 'deploy'
  }

  # Default release mode used for the project if no such parameter given via Rakefile
  DEFAULT_RELEASE = 'dbg'

  # Default test framework used for linking test case binaries
  DEFAULT_TEST_FW = ''

  # Default optimization levels used for compiling binaries
  DEFAULT_OPTIMIZATION_DBG      = '-O0'
  DEFAULT_OPTIMIZATION_RELEASE  = '-O3'

  # Default language standards
  DEFAULT_LANGUAGE_STD_C   = '-std=gnu99'
  DEFAULT_LANGUAGE_STD_CPP = '-std=c++03'

  # Default software version string
  DEFAULT_SW_VERSION = 'unversioned'

  # Default for if binaries should be stripped
  DEFAULT_STRIPPED = false

  # Default for if hex files should be generated from app binaries
  DEFAULT_GENERATE_HEX = false

  # Default for if bin files should be generated from app binaries
  DEFAULT_GENERATE_BIN = false

  # Default for if map files should be generated from app binaries
  DEFAULT_GENERATE_MAP = false


  class Default

    def self.suffixes
      RakeOE::DEFAULT_SUFFIXES
    end

    def self.dirs
      RakeOE::DEFAULT_DIRS
    end

    def self.release
      RakeOE::DEFAULT_RELEASE
    end

    def self.test_fw
      RakeOE::DEFAULT_TEST_FW
    end

    def self.optimization_dbg
      RakeOE::DEFAULT_OPTIMIZATION_DBG
    end

    def self.optimization_release
      RakeOE::DEFAULT_OPTIMIZATION_RELEASE
    end

    def self.lang_std_c
      RakeOE::DEFAULT_LANGUAGE_STD_C
    end

    def self.lang_std_cpp
      RakeOE::DEFAULT_LANGUAGE_STD_CPP
    end

    def self.sw_version
      RakeOE::DEFAULT_SW_VERSION
    end

    def self.stripped
      RakeOE::DEFAULT_STRIPPED
    end

    def self.generate_hex
      RakeOE::DEFAULT_GENERATE_HEX
    end

    def self.generate_bin
      RakeOE::DEFAULT_GENERATE_BIN
    end

    def self.generate_map
      RakeOE::DEFAULT_GENERATE_MAP
    end

    def self.prj_settings
      {
        'ADD_SOURCE_DIRS'   => '',
        'IGNORED_SOURCES'   => '',
        'EXPORTED_INC_DIRS' => 'include/',
        'ADD_INC_DIRS'      => '',
        'TEST_SOURCE_DIRS'  => 'test/ tests/',
        'ADD_CFLAGS'        => '',
        'ADD_CXXFLAGS'      => '',
        'ADD_LIBS'          => '',
        'ADD_LDFLAGS'       => '',
        'USE_QT'            => '',
        'IGNORED_PLATFORMS' => ''
      }
    end


  end
end

