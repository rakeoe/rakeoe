# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rakeoe/version'

Gem::Specification.new do |spec|
  spec.name          = "rakeoe"
  spec.version       = Rakeoe::VERSION
  spec.authors       = ["Daniel Schnell"]
  spec.email         = ["dschnell@skerpa.com"]
  spec.description   = %q{RakeOE : Rake Optimized for Embedded
                          A build system for test driven Embedded C/C++ Development based on Ruby Rake.
                          RakeOE is a build system for application development. It can parse OpenEmbedded/Yocto environment files.
                          In this way it knows how to cross compile in whatever target platform the cross compiler builds.
                          It uses automatically the appropriate include paths and libraries of the given platform.}
  spec.summary       = %q{RakeOE : Rake Optimized for Embedded. A build system for test driven Embedded C/C++ Development}
  spec.homepage      = ""
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
