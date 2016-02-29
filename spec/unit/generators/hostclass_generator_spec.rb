require 'spec_helper'

describe 'HostClassGenerator' do

  after(:each) do
    FileUtils.rm(spec_file) if File.exists?(spec_file)
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'classes')
  end

  let(:generator_opts) do
    {:manifest_file => sample_file, :template_dir => retrospec_templates_path}
  end

  let(:sample_file) do
    File.join(fixtures_path, 'manifests', 'sql.pp')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:spec_file) do
    path = File.join(module_path, 'spec', 'classes', 'sql_spec.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::HostClassGenerator.new(module_path, generator_opts)
  end

  let(:context) do
    generator.load_context_data
  end

  let(:spec_file_contents) do
    File.read(generator.generate_spec_file)
  end

  it 'should create spec file' do
    expect(generator.run).to eq(spec_file)
    expect(File.exists?(spec_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_spec_path).to eq(spec_file)
  end

  it 'should generate the content' do
    data = ''
    expect(spec_file_contents).to eq(data)
  end

  it 'should have a name' do
    expect(context.type_name).to eq('sql')
  end

  it 'should have a resource_type_name' do
    expect(context.resource_type_name).to eq('class')
  end

  it 'should have a type' do
    expect(context.resource_type).to eq(Puppet::Pops::Model::HostClassDefinition)
  end

  it 'should have parameters' do
    expect(context.parameters).to be_instance_of(String)
    expect(context.parameters.split(',').count).to eq(9)
    # if the test returns more than the expected count there is an extra comma
    # although technically it doesn't matter
  end

  it 'should have resources' do
    expect(context.resources.count).to eq(4)
  end

  describe 'spec files' do
    let(:generated_files) do
      [File.join(spec_files_path, 'another_resource_spec.rb'),
        File.join(spec_files_path, 'inherits_params_spec.rb'),
        File.join(spec_files_path, 'one_resource_spec.rb'),
        File.join(spec_files_path, 'params_spec.rb')]
    end

    it 'should generate a bunch of files' do
      files = Retrospec::Puppet::Generators::HostClassGenerator.generate_spec_files(module_path)
      expect(files).to eq(generated_files)
    end
  end

  describe 'apache test' do
    let(:sample_file) do
      File.join(fixtures_path, 'manifests', 'apache.pp')
    end
    it 'should generate test for apache' do
      expect(generator.generate_content).to eq('')
    end
  end

end
