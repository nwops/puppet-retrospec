require 'spec_helper'

describe Retrospec::Puppet::Generators::DefinitionGenerator do
  before(:each) do
    FileUtils.rm_rf(spec_files_path) if File.exist?(spec_files_path)
  end

  let(:generator_opts) do
    { :manifest_file => sample_file, :template_dir => retrospec_templates_path }
  end

  let(:sample_file) do
    File.join(module_path, 'manifests', 'one_define.pp')
  end

  let(:context) do
    generator.load_context_data
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'defines')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:spec_file) do
    path = File.join(module_path, 'spec', 'defines', 'one_define_spec.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::DefinitionGenerator.new(module_path, generator_opts)
  end

  let(:spec_file_contents) do
    File.read(generator.generate_spec_file)
  end

  it 'should create spec file' do
    expect(generator.run).to eq(spec_file)
    expect(File.exist?(spec_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_spec_path).to eq(spec_file)
  end

  it 'should have a name' do
    expect(context.type_name).to eq('one_resource::one_define')
  end

  it 'should have a resource_type_name' do
    expect(context.resource_type_name).to eq('one_resource::one_define')
  end

  it 'should have a type' do
    expect(context.resource_type).to eq(Puppet::Pops::Model::ResourceTypeDefinition)
  end

  it 'should have parameters' do
    expect(context.parameters).to be_instance_of(String)
    expect(context.parameters.strip.chomp.split("\n").count).to eq(1)
    # if the test returns more than the expected count there is an extra comma
    # although technically it doesn't matter
  end

  it 'should have resources' do
    resources = ["\n  it do\n    is_expected.to contain_notify('hello')\n  end  "]
    expect(context.resources).to eq(resources)
  end

  describe 'content' do
    let(:data) do
      /contain_notify\('hello'\)/
    end
    it 'should generate the content' do
      expect(spec_file_contents).to match(data)
      expect(spec_file_contents).to match(/# one: "one_value",/)
    end
  end

  describe 'spec files' do
    let(:generated_files) do
      [File.join(spec_files_path, 'one_define_spec.rb'),
       File.join(spec_files_path, 'sub', 'settings_define_spec.rb')].sort
    end
    it 'should generate a bunch of files' do
      files = Retrospec::Puppet::Generators::DefinitionGenerator.generate_spec_files(module_path, generator_opts)
      expect(files.sort).to eq(generated_files)
    end
  end
end
