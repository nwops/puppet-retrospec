require 'retrospec-puppet'
require 'rspec'
require 'puppet'
require 'pry'

def fixture_modules_path
  @fixture_module_path ||= File.expand_path(File.join(fixtures_path, 'modules'))
end

def gem_template_path
  @gem_template_path ||= File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'lib', 'retrospec', 'plugins', 'v1', 'plugin', 'templates'))
end

def sample_module_path
   File.join(fixtures_path, 'fixture_modules', 'sample_module')
end

def fixtures_path
  @fixtures_path ||= File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
end

def fixtures_facts_path
  @fixtures_facts_path ||= File.expand_path(File.join(fixtures_path, 'facts'))
end

def fixtures_type_path
  @fixtures_type_path ||= File.expand_path(File.join(fixtures_path, 'types'))
end

def fixtures_provider_path
  @fixtures_provider_path ||= File.expand_path(File.join(fixtures_path, 'providers'))
end

def fixtures_functions_path
  @fixtures_functions_path ||= File.expand_path(File.join(fixtures_path, 'functions'))
end

def clean_up_spec_dir(dir)
  # puts "removing directory #{dir}"
  FileUtils.rm_rf(File.join(dir, 'spec'))
  FileUtils.rm_f(File.join(dir, 'Gemfile'))
  FileUtils.rm_f(File.join(dir, '.fixtures.yml'))
  FileUtils.rm_f(File.join(dir, 'Rakefile'))
end

def retrospec_templates_path
  # I like to develop the templates at the same time as this gem
  # but I keep the templates in another repo
  # as a side effect, puppet retrospec will pick up this environment variable as well
  ENV['RETROSPEC_TEMPLATES_DIR'] ||= File.join(ENV['HOME'], 'github', 'retrospec-templates')
end

def install_module(module_name)
  FileUtils.mkdir_p(fixture_modules_path)
  puts `puppet module install -i #{fixture_modules_path} #{module_name}`
  Dir.glob(File.join(fixture_modules_path, '**', 'spec')).each do |dir|
    clean_up_spec_dir(dir)
  end
end
