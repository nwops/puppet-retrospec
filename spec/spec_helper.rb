require 'puppet-retrospec'
require 'rspec'
require 'puppet'

def fixture_modules_path
  @fixture_module_path ||= File.expand_path(File.join(fixtures_path, 'modules'))
end

def fixtures_path
  @fixtures_path ||= File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
end

def install_module(module_name)
  FileUtils.mkdir_p(fixture_modules_path)
  puts "Downloading modules to fixtures directory"
  `puppet module install -i #{fixture_modules_path} #{module_name}`
  Dir.glob('spec/fixtures/modules/**/spec').each do |dir|
    FileUtils.rm_rf(dir)
  end
end



