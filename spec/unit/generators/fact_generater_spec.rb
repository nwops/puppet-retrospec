require 'spec_helper'

describe "fact generator" do

  before :all do
    initialize_templates
  end

  before :each do
    FileUtils.rm_rf(facter_spec_dir)
  end

  after :each do
    FileUtils.rm_f(generator.fact_name_path) # ensure the file does not exist
  end

  let(:facter_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'facter')
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:context) do
    {:name => 'datacenter', :template_dir => retrospec_templates_path }
  end

  let(:generator) do
    Retrospec::Puppet::Generators::FactGenerator.new(module_path, context )
  end

  describe :datacenter do
    before(:each) do
      allow(generator).to receive(:facter_dir).and_return(fixtures_facts_path)
      allow(generator).to receive(:fact_name_path).and_return(File.join(module_path, 'lib', 'facter', "#{generator.fact_name}.rb"))
    end

    let(:context) do
      {:name => 'datacenter', :template_dir => retrospec_templates_path}
    end
    it 'returns facter dir' do
      expect(generator.facter_dir).to eq(fixtures_facts_path)
    end

    it 'returns module path' do
      expect(generator.facter_spec_dir).to eq(facter_spec_dir)
    end

    it 'can return fact name' do
      expect(generator.fact_name).to eq('datacenter')
    end

    it 'can generate a fact file' do
      expect(generator.generate_fact_file.count).to eq(6)
      expect(File.exists?(File.join(generator.facter_dir, "#{generator.fact_name}.rb")))
    end

    it 'can generate a spec file' do
      expect(generator.generate_fact_spec_files.count).to eq(6)
    end
  end

  describe :oracle_controls do
    before(:each) do
      allow(generator).to receive(:facter_dir).and_return(fixtures_facts_path)
      allow(generator).to receive(:fact_name_path).and_return(File.join(module_path, 'lib', 'facter', "#{generator.fact_name}.rb"))
    end

    let(:context) do
      {:name => 'oracle_controls',:template_dir => retrospec_templates_path}
    end

    it 'can generate a spec file' do
      allow(generator).to receive(:fact_files).and_return([File.join(fixtures_facts_path, 'oracle_controls.rb')])
      expect(generator.generate_fact_spec_files.count).to eq(2)
    end
  end

  describe 'real module' do
    let(:module_path) do
      sample_module_path
    end

    it 'can generate a spec file' do
      expect(generator.generate_fact_spec_files).to eq([File.join(facter_spec_dir, 'fix_installed_spec.rb')])
    end
  end
end
