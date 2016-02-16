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

  it 'should create spec file' do
    expect(generator.run).to eq(spec_file)
    expect(File.exists?(spec_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_spec_path).to eq(spec_file)
  end

  it 'should generate the content' do
    expect(generator.generate_content).to eq('')
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
