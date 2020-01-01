# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pluggaloid/version'

Gem::Specification.new do |spec|
  spec.name          = "pluggaloid"
  spec.version       = Pluggaloid::VERSION
  spec.authors       = ["Toshiaki Asai"]
  spec.email         = ["toshi.alternative@gmail.com"]
  spec.summary       = %q{Extensible plugin system}
  spec.description   = %q{Pluggaloid is extensible plugin system for mikutter.}
  spec.homepage      = "https://rubygems.org/gems/pluggaloid"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'delayer', '>= 1.1.0', '< 2.0'
  spec.add_dependency 'instance_storage', ">= 1.0.0", "< 2.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.3.2"
  spec.add_development_dependency "minitest", ">= 5.11.3"
end
