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
    :build => 'build'
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
end

