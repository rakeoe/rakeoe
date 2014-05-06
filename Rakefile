require 'bundler/gem_tasks'
require 'rspec/core/rake_task'


# Default directory to look in is `/spec`
# Run with `rake spec`
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color', '--format', 'nested']
end

task :default => :spec
task :test => :spec
