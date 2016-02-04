require 'spec_helper'

describe 'report_generator' do

  after(:each) do
    FileUtils.rm(report_file) if File.exists?(report_file)
    FileUtils.rm(report_spec_file) if File.exists?(report_spec_file)
  end

  let(:generator_opts) do
    {:name => 'test',  :template_dir => retrospec_templates_path}
  end

  let(:module_path) do
    sample_module_path
  end

  let(:report_file) do
    path = File.join(module_path, 'lib', 'puppet', 'reports', 'test.rb')
  end

  let(:report_spec_file) do
    path = File.join(module_path, 'spec', 'unit', 'puppet', 'reports', 'test_spec.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::ReportGenerator.new(module_path, generator_opts)
  end

  it 'should create files without error' do
    files = generator.run
    expect(files.include?(report_file)).to eq(true)
    expect(File.exists?(report_file)).to eq(true)
    expect(files.include?(report_spec_file)).to eq(true)
    expect(File.exists?(report_spec_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_path).to eq(report_file)
  end

  it 'should produce correct spec file path' do
    expect(generator.item_spec_path).to eq(report_spec_file)
  end

end
