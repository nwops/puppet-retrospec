# encoding: utf-8

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb'].exclude('spec/fixtures/**/*')
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
