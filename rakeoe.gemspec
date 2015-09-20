# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rakeoe/version'

Gem::Specification.new do |spec|
  spec.name          = "rakeoe"
  spec.version       = RakeOE::VERSION
  spec.authors       = ["Daniel Schnell"]
  spec.email         = ["dschnell@skerpa.com"]
  spec.description   = %q{Rake Optimized for Embedded: RakeOE is a build system for application/library development.
                          RakeOE utilizes the power of Rake and the easyness of Ruby to make build management for
                          embedded C/C++ development as easy and straight-forward as possible.
                          It's possible to use it on the command line or to integrate it into an IDE like Eclipse.
                          It runs on Windows, Linux and Mac OS X.
                         }
  spec.summary       = %q{Rake Optimized for Embedded: build system for test driven Embedded C/C++ Development based on Ruby Rake.}
  spec.homepage      = "http://rakeoe.github.io/rakeoe/"
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler',      '~> 1.3'
  spec.add_development_dependency 'rspec',        '~> 3'

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_dependency 'rake', '~> 10'
end
