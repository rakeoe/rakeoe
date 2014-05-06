require 'bundler/setup'
Bundler.setup

require 'rakeoe'
require 'factory_girl'

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
