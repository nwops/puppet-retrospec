require 'spec_helper'

describe 'HostClassGenerator' do
  before(:each) do
    FileUtils.rm(spec_file) if File.exist?(spec_file)
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'classes')
  end

  let(:generator_opts) do
    { :manifest_file => sample_file, :template_dir => retrospec_templates_path }
  end

  let(:sample_file) do
    File.join(module_path, 'manifests', 'nested_param.pp')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:spec_file) do
    path = File.join(module_path, 'spec', 'classes', 'nested_param_spec.rb')
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
    expect(File.exist?(spec_file)).to eq(true)
  end
end
