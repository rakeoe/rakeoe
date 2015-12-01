
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
  # of given config. Provides all rake tasks.
  #
  # @param config [RakeOE::Config]      Configuration as provided by project Rakefile
  #
  # @return [RakeOE::Toolchain]         Toolchain object
  def init(config)

    RakeOE::PrjFileCache.set_defaults(RakeOE::Default.prj_settings)

    src_dirs = []
    src_dirs += config.directories[:src] if config.directories[:src]
    src_dirs += config.directories[:apps] if config.directories[:apps]
    src_dirs += config.directories[:libs] if config.directories[:libs]

    RakeOE::PrjFileCache.sweep_recursive(src_dirs.uniq)

    toolchain = RakeOE::Toolchain.new(config)
    RakeOE::PrjFileCache.join_regex_keys_for!(toolchain.target)
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

          desc "Run all #{type} tests and create junit xml output"
          task :junit
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

    toolchain
  end
end

include RakeOE
