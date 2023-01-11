# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tabulo/version'

Gem::Specification.new do |spec|
  spec.name          = "tabulo"
  spec.version       = Tabulo::VERSION
  spec.authors       = ["Matthew Harvey"]
  spec.email         = ["software@matthewharvey.net"]

  spec.summary       = "Terminal table generator"
  spec.description   = "Plain text table generator with a column-based API"
  spec.homepage      = "https://github.com/matt-harvey/tabulo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.10"

  spec.metadata = {
    "source_code_uri" => "https://github.com/matt-harvey/tabulo",
    "changelog_uri"   => "https://raw.githubusercontent.com/matt-harvey/tabulo/master/CHANGELOG.md"
  }

  spec.add_runtime_dependency "tty-screen", "0.8.1"
  spec.add_runtime_dependency "unicode-display_width", "~> 2.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.11"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-lcov"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "github-markup"
  spec.add_development_dependency "rake-version", "~> 1.0"
end
