# -*- ruby -*-

require 'rake'
require 'rakeoe/binary_base'

module RakeOE
  
  # Finds all source codes in specified directory
  # and encapsulates App projects
  class App < RakeOE::BinaryBase
    attr_reader   :binary

    #
    # The following parameters are expected in given hash params:
    #
    # @param  [String] name       Name of the application
    # @param  [String] settings   Settings for application
    # @param  [String] tool       Toolchain builder to use
    #
    def initialize(name, settings, tool)
      super(:name => name,
      :settings => settings,
      :bin_dir => tool.settings['APP_OUT'],
      :toolchain => tool)

      # We need to divide our app into an app lib and the app main object file
      # for testing.
      #
      # This is the convention: 'name.o' is supposed to contain the main() function.
      # All other object files are linked into a static library 'libname-app.a'.
      # Finally both are linked together with all dependent external libraries
      # to the application binary.
      #
      # In case of tests, the test objects are linked against 'libname-app.a'
      # and all dependent external libraries.
      #
      @app_main_obj = objs.select{|obj| File.basename(obj) == "#{name}.o"}
      @app_main_dep = @app_main_obj.map {|obj| obj.ext('.d')}
      @app_lib_objs = objs - @app_main_obj
      @app_lib_deps = @app_lib_objs.map {|obj| obj.ext('.d')}
    end


    # create all rules, tasks and dependencies
    # for the app
    def create
      unless project_can_build?
        disable_build
        return
      end

      # create build directory
      directory build_dir

      binary_targets = paths_of_local_libs() + @app_main_dep + @app_main_obj

      # This is only necessary if we have more than a single app main file
      if @app_lib_objs.any?
        create_app_lib_rules(binary_targets)
      end

      prj_libs = search_libs(settings)
      linked_libs = prj_libs[:all]

      file binary => binary_targets do
        tc.app(:libs => linked_libs,
        :app => binary,
        :objects => @app_main_obj,
        :settings => @settings,
        :includes => src_dirs)
      end

      if test_objs.any?
        create_test_rules(binary_targets, linked_libs)
      end

      # link dependent library to lib target (e.g. libXXX.a => lib:XXX)
      # this makes a connection from the dependency in variable libs above to the appropriate rule as defined
      # inside the lib class. If one would know the absolute path to the library, one could alternatively draw
      # a dependency to the lib binary instead of the name, then these two rules wouldn't be necessary
      rule '.a' => [ proc {|tn| 'lib:' + File.basename(tn.name).gsub('lib', '').gsub('.a','') } ]
      rule '.so' => [ proc {|tn| 'lib:' + File.basename(tn.name).gsub('lib', '').gsub('.so','') } ]

      # create standard rules
      create_build_rules

      desc "Create #{name}"
      task name => binary_targets + [binary]

      #desc "Clean  #{name}"
      task name+'_clean' do
        tc.rm (objs + deps + [binary]).join(' ')
      end

      # add this application as dependency for the app:all task
      task :all => name

      # create runner
      task "#{name}_run" => name do
        tc.run binary
      end

      # add files for the clean rule
      CLEAN.include('*.o', build_dir)
      CLEAN.include(@app_lib, build_dir)
      CLEAN.include(binary, build_dir)
      CLOBBER.include('*.d', build_dir)
    end

    def create_app_lib_rules(binary_targets)
      app_lib_targets = @app_lib_deps + @app_lib_objs + [@settings['PRJ_FILE']]
      file @app_lib => app_lib_targets do
        tc.lib(:objects => @app_lib_objs,
        :lib => @app_lib,
        :settings => @settings)
      end

      # add this to the dependent targets of app binary
      binary_targets << @app_lib

      # we treat the app lib as an object file. This makes linking easier.
      @app_main_obj << @app_lib
    end


    def create_test_rules(binary_targets, linked_libs)
      namespace 'test' do
        desc "Test #{name}"
        task "#{name}" => test_binary do
          tc.run(test_binary)
        end

        # Build the library and execute tests
        task "#{name}_junit" => test_binary do
          tc.run_junit_test(test_binary)
        end

        # 'hidden' task just for building the test
        task "#{name}_build" => test_binary

        file test_binary => [@test_fw.binary_path] + binary_targets + test_deps + test_objs do
          tc.test(:objects => test_objs + [@app_lib],
          :test => test_binary,
          :libs => linked_libs,
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
