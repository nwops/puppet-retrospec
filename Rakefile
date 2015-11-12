# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = 'puppet-retrospec'
  gem.homepage = 'http://github.com/nwops/puppet-retrospec'
  gem.license = 'MIT'
  gem.summary = %(Generates puppet rspec test code based on the classes and defines inside the manifests directory. Aims to reduce some of the boilerplate coding with default test patterns.)
  gem.description = %(Retrofits and generates valid puppet rspec test code to existing modules)
  gem.email = 'corey@logicminds.biz'
  gem.authors = ['Corey Osman']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb'].exclude('spec/fixtures/**/*_spec.rb')
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
