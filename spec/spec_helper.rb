require 'retrospec-puppet'
require 'rspec'
require 'puppet'
require 'pry'

def fixture_modules_path
  @fixture_module_path ||= File.expand_path(File.join(fixtures_path, 'modules'))
end

def fixtures_path
  @fixtures_path ||= File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
end

def fixtures_facts_path
  @fixtures_facts_path ||= File.expand_path(File.join(fixtures_path, 'facts'))
end

def clean_up_spec_dir(dir)
  #puts "removing directory #{dir}"
  FileUtils.rm_rf(File.join(dir, 'spec'))
  FileUtils.rm_f(File.join(dir, 'Gemfile'))
  FileUtils.rm_f(File.join(dir, '.fixtures.yml'))
  FileUtils.rm_f(File.join(dir, 'Rakefile'))

end

def install_module(module_name)
  FileUtils.mkdir_p(fixture_modules_path)
  puts `puppet module install -i #{fixture_modules_path} #{module_name}`
  Dir.glob(File.join(fixture_modules_path, '**','spec')).each do |dir|
     clean_up_spec_dir(dir)
  end
end



