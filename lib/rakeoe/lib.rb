# -*- ruby -*-
require 'rake'
require 'rakeoe/binary_base'

module RakeOE
  # Finds all source codes in specified directory
  # and encapsulates lib projects
  class Lib < RakeOE::BinaryBase
    attr_reader   :binary

    #
    # The following parameters are expected in given hash params:
    #
    #  @param [String]  name        Name of the library
    #  @param [String]  settings    Settings for library
    #  @param [Hash]    toolchain   Toolchain builder to use
    #
    def initialize(name, settings, toolchain)
      super(:name => name,
      :settings => settings,
      :bin_dir => toolchain.settings['LIB_OUT'],
      :toolchain => toolchain)
    end


    # Create all rules and tasks for the lib
    # XXX DS: we have to make a consistent step by step approach for each binary type
    # XXX DS: something like: 1.) search library dependencies, 2.)build paths, 3.) create main rule,
    # XXX DS: 4.) make test rules, 5, make additional rules (clean/all, ...) etc.
    def create
      unless project_can_build?
        disable_build
        return
      end

      desc "Create #{name}"

      prj_libs = search_libs(settings)
#puts "prj_libs for #{name}: #{prj_libs}"
      task name => [binary]
      dependency_paths = paths_of_local_libs + deps + objs
      file binary => dependency_paths do
        tc.test_all_files_exist?(dependency_paths)
        tc.lib(:objects => objs,
               :lib => binary,
               :libs => prj_libs[:all],
               :settings => @settings)
      end

      if test_objs.any? && (tc.config.test_fw.size > 0)
        create_test_rules(:libs => prj_libs)
      end

      task name+'_clean' do
        tc.rm (objs + deps + [binary]).join(' ')
      end

      # add library for the lib:all task
      task :all => name unless tc.test_frameworks.include?(name)

      # create build directory
      directory build_dir

      # create standard build rules
      create_build_rules

      CLEAN.include('*.o', build_dir)
      CLEAN.include(binary, build_dir)
      CLOBBER.include('*.d', build_dir)
    end


    # Create all rules and tasks
    def create_test_rules(params)
      namespace 'test' do
        # Build the library and execute tests
        desc "Test #{name}"
        task "#{name}" => test_binary do
          tc.run(test_binary)
        end

        # Build the library, execute tests and write results to file
        task "#{name}_junit" => test_binary do
          tc.run_junit_test(test_binary)
        end

        # 'hidden' task just for building the test
        task "#{name}_build" => test_binary
        prj_libs = params[:libs]

        # main rule for the test binary
        file test_binary => [@test_fw.binary_path] + paths_of_local_libs + [binary] + test_deps + test_objs do
          tc.test(:objects => test_objs,
                  :test => test_binary,
                  :libs => prj_libs[:all] + [name],
                  :framework => @test_fw.name,
                  :settings => @settings,
                  :includes => test_dirs)
        end
        CLEAN.include(test_binary, build_dir)
        task :all => "#{name}"
        task :junit => "#{name}_junit"
        task :build => "#{name}_build"
      end
    end
  end
end
