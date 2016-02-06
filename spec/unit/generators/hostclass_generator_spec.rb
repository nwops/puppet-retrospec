require 'spec_helper'

describe 'hostclass_generator' do

  after(:each) do
    FileUtils.rm(hostclass_spec_file) if File.exists?(hostclass_spec_file)
  end

  let(:generator_opts) do
    {:name => 'testclass',  :template_dir => retrospec_templates_path}
  end

  let(:sample_file) do
    '/Users/cosman/singlestone/modules/sql2014/manifests/init.pp'
  end

  let(:module_path) do
    sample_module_path
  end

  let(:hostclass_spec_file) do
    path = File.join(module_path, 'spec', 'classes', 'testclass_spec.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::HostClassGenerator.new(module_path, generator_opts)
  end

  it 'should create spec file' do
    expect(generator.run).to eq(hostclass_spec_file)
    expect(File.exists?(hostclass_spec_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_spec_path).to eq(hostclass_spec_file)
  end

  it 'should generate the content' do
    expect(generator.generate_content(sample_file)).to eq('')
  end
end
