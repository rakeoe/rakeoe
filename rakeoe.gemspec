# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rakeoe/version'

Gem::Specification.new do |spec|
  spec.name          = "rakeoe"
  spec.version       = RakeOE::VERSION
  spec.authors       = ["Daniel Schnell"]
  spec.email         = ["dschnell@skerpa.com"]
  spec.description   = %q{Rake Optimized for Embedded: build system for test driven Embedded C/C++ Development based on Ruby Rake.
                          RakeOE can be used for application and library development on Windows, Mac OSX and Linux.
                          It uses OpenEmbedded/Yocto compatible platform files to compile in whatever target platform the compiler builds. It is
                          used for MicroControllers and Linux-flavored systems alike. It's possible to combine multiple platforms in one
                          common project. RakeOE is easy to use while maintaining strict dependency tracking.
                         }
  spec.summary       = %q{Rake Optimized for Embedded: build system for test driven Embedded C/C++ Development based on Ruby Rake.}
  spec.homepage      = "http://rakeoe.github.io/rakeoe/"
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  
  spec.add_dependency "rake"
end
