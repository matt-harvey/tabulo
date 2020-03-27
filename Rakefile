require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake-version"
require "yard"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

RakeVersion::Tasks.new do |v|
  v.copy "lib/tabulo/version.rb"
  v.copy "README.md", all: true
end

YARD::Rake::YardocTask.new do |t|
  t.options = ["--markup-provider=redcarpet", "--markup=markdown"]
end
