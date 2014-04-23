# -*- ruby -*-
require 'rakeoe/defaults'

module RakeOE
  # Project wide configurations
  module Config
    class << self
      attr_accessor :suffices, :directories, :platform , :release, :test_fw, :optimization_dbg, :optimization_release,
                    :language_standard_c, :language_standard_cpp

      def initialize
        # file extensions used for the project
        @suffices = RakeOE::DEFAULT_SUFFICES

        # directories used for the project
        @directories = RakeOE::DEFAULT_DIRS

        # platform configuration used for the project
        @platform = RakeOE::DEFAULT_PLATFORM

        # release mode used for the project if no such parameter given via environment variable
        @release = RakeOE::DEFAULT_RELEASE

        # test framework used for linking test case binaries
        @test_fw = RakeOE::DEFAULT_TEST_FW

        # optimization levels used for compiling binaries
        @optimization_dbg = RakeOE::DEFAULT_OPTIMIZATION_DEBUG
        @optimization_release = RakeOE::DEFAULT_OPTIMIZATION_RELEASE

        # Language standard (c++03, c99, etc. )
        @language_standard_c = RakeOE::DEFAULT_LANGUAGE_STANDARD_C
        @language_standard_cpp = RakeOE::DEFAULT_LANGUAGE_STANDARD_CPP
      end
    end
  end
end

