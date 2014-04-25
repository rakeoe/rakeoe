
require 'rake'
require 'rake/dsl_definition'
require 'rake/clean'

require 'rakeoe/config'
require 'rakeoe/version'
require 'rakeoe/defaults'
require 'rakeoe/key_value_reader'
require 'rakeoe/toolchain'
require 'rakeoe/qt_settings'
require 'rakeoe/lib'
require 'rakeoe/app'
require 'rakeoe/prj_file_cache'

module RakeOE

  include Rake::DSL   # for #task, #desc, #namespace

  # Initialize RakeOE project. Reads & parses all prj.rake files
  # of given config.
  #
  # @param config [RakeOE::Config]      Configuration as provided by project Rakefile
  #
  def init(config)

    RakeOE::PrjFileCache.sweep_recursive(config.directories[:apps] + config.directories[:libs])

    toolchain = RakeOE::Toolchain.new(config)
    
    #
    # Top level tasks
    #
    %w[lib app].each do |type|
      namespace type do
        # Introduce type:all
        #
        # All libs/apps will make themselves dependent on this task, so whenever you call
        #   'rake lib:all' or 'rake app:all'
        # all libs/apps will thus be generated automatically
        desc "Create all #{type}s"
        task :all

        case type
        when 'lib'
          RakeOE::PrjFileCache.for_each('LIB') do |name, settings|
            RakeOE::Lib.new(name, settings, toolchain).create
          end

          RakeOE::PrjFileCache.for_each('SOLIB') do |name, settings|
            RakeOE::Lib.new(name, settings, toolchain).create
          end

        when 'app'
          RakeOE::PrjFileCache.for_each('APP') do |name, settings|
            RakeOE::App.new(name, settings, toolchain).create
          end
        else
          raise "No such type #{type} supported"
        end

        # Introduce type:test:all
        #
        # All tests in lib/app will make themselves dependent on this task, so whenever you call
        #   'rake lib:test:all'
        # all available library tests will be generated automatically before execution
        namespace 'test' do
          desc "Run all #{type} tests"
          task :all
        end
      end
    end

    desc 'Deploys apps and dynamic objects to deploy_dir/bin, deploy_dir/lib'
    task :deploy, [:deploy_dir] => :all do |t, args|
      args.with_defaults(:deploy_dir => config.directories[:deploy])
      puts "Copy binaries from #{toolchain.build_dir} => #{args.deploy_dir}"
      begin
        FileUtils.mkdir_p("#{args.deploy_dir}/bin")
        FileUtils.mkdir_p("#{args.deploy_dir}/lib")
      rescue
        raise
      end

      # deploy binaries
      Dir.glob("#{toolchain.build_dir}/apps/*").each do |file|
        next if file.end_with?('.bin')
        FileUtils.cp(file, "#{args.deploy_dir}/bin/#{File.basename(file)}") if File.executable?(file)
      end
      # deploy dynamic libraries
      Dir.glob("#{toolchain.build_dir}/libs/*.so").each do |file|
        next if file.end_with?('.bin')
        FileUtils.cp(file, "#{args.deploy_dir}/lib/")
      end
    end

    desc 'Dump configuration & toolchain variables'
    task :dump do
      puts
      config.dump
      puts
      toolchain.dump
      puts
    end
  
    task :all => %w[lib:all app:all]
    task :test => %w[lib:test:all app:test:all]
    task :test_build => %w[lib:test:build app:test:build]
    task :junit => %w[lib:test:junit app:test:junit]
    task :default => :all

    # kind of mrproper/realclean
    CLOBBER.include('*.tmp', "#{config.directories[:build]}/*")
  end
end

include RakeOE
