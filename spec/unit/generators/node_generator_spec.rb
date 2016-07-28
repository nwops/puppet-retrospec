require 'spec_helper'

describe Retrospec::Puppet::Generators::NodeGenerator do
  after(:each) do
    FileUtils.rm(spec_file) if File.exist?(spec_file)
  end

  let(:generator_opts) do
    { :manifest_file => sample_file, :template_dir => retrospec_templates_path }
  end

  let(:sample_file) do
    File.join(module_path, 'manifests', 'node_file.pp')
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'hosts')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:spec_file) do
    path = File.join(module_path, 'spec', 'hosts', 'node_file_spec.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::NodeGenerator.new(module_path, generator_opts)
  end

  let(:spec_file_contents) do
    File.read(generator.generate_spec_file)
  end

  xit 'should create spec file' do
    expect(generator.run).to eq(spec_file)
    expect(File.exist?(spec_file)).to eq(true)
  end

  xit 'should produce correct file name' do
    expect(generator.item_spec_path).to eq(spec_file)
  end

  xit 'should generate the content' do
    data = ''
    expect(spec_file_contents).to eq(data)
  end

  describe 'spec files' do
    let(:generated_files) do
      [File.join(spec_files_path, 'site_spec.rb')]
    end
    xit 'should generate a bunch of files' do
      files = Retrospec::Puppet::Generators::NodeGenerator.generate_spec_files(module_path, generator_opts)
      expect(files).to eq(generated_files)
    end
  end
end
