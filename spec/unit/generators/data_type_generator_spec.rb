require 'spec_helper'

describe 'datatype_generator' do
  before(:each) do
    FileUtils.rm_rf(spec_files_path) if File.exist?(spec_files_path)
  end

  let(:generator_opts) do
    { :name => 'sudoers_entry', :puppet_context => puppet_context, :template_dir => retrospec_templates_path
    }
  end

  let(:generator_opts) do
    { :manifest_file => sample_file, :template_dir => retrospec_templates_path }
  end

  let(:sample_file) do
    File.join(fixtures_path, 'manifests', 'sql.pp')
  end

  let(:module_path) do
    sample_module_path
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'type_aliases')
  end

  let(:datatypes_path) do
    File.join(module_path, 'types')
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
    Retrospec::Puppet::Generators::DataTypeGenerator.new(module_path, generator_opts)
  end

  it 'should create datatype spec file' do
    Retrospec::Puppet::Generators::DataTypeGenerator.generate_spec_files(module_path, generator_opts)
    expect(File.exist?(File.join(spec_files_path, 'sudoers_entry_spec.rb'))).to eq(true)
  end

  it 'should create datatype ext spec file' do
    Retrospec::Puppet::Generators::DataTypeGenerator.generate_spec_files(module_path, generator_opts)
    expect(File.exist?(File.join(spec_files_path, 'ext','sudoers_entry_spec.rb'))).to eq(true)
  end

  it '#self.manifest_files' do
    files = Retrospec::Puppet::Generators::DataTypeGenerator.manifest_files(module_path)
    expect(files.count).to be > 0
  end

end