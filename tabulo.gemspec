# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tabulo/version'

Gem::Specification.new do |spec|
  spec.name          = "tabulo"
  spec.version       = Tabulo::VERSION
  spec.authors       = ["Matthew Harvey"]
  spec.email         = ["software@matthewharvey.net"]

  spec.summary       = "Enumerable ASCII table"
  spec.description   = "Enumerable ASCII table"
  spec.homepage      = "https://github.com/matt-harvey/tabulo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.14.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-tomdoc"
end
