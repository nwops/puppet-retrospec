require 'spec_helper'

describe 'task_generator' do
  before(:each) do
    FileUtils.rm_rf(tasks_path) if File.exist?(tasks_path)
  end

  let(:generator_opts) do
    { :name => 'task1', :puppet_context => puppet_context, :template_dir => retrospec_templates_path,
      task_type: 'ruby', task_params: 'name, all' }
  end

  let(:module_path) do
    sample_module_path
  end

  let(:tasks_path) do
    File.join(module_path, 'tasks')
  end

  let(:puppet_context) do
    path = File.join(fixture_modules_path, 'tomcat')
    opts = { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
             :enable_user_templates => false, :template_dir => retrospec_templates_path }
    mod = Retrospec::Plugins::V1::Puppet.new(opts[:module_path], opts)
    mod.post_init
    mod.context
  end

  let(:generator) do
    Retrospec::Puppet::Generators::TaskGenerator.new(module_path, generator_opts)
  end

  it 'should create files without error' do
    expect(generator.generate_task_files).to eq([File.join(tasks_path, 'task1.rb'), File.join(tasks_path, 'task1.json')])
    expect(File.exist?(tasks_path)).to eq(true)
  end

  it 'should return the correct task file' do
    expect(generator.task_filepath).to eq(File.join(tasks_path, 'task1.rb'))
  end

  it 'should return the correct task file' do
    expect(generator.task_params_filepath).to eq(File.join(tasks_path, 'task1.json'))
  end
end
