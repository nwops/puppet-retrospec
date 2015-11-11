require 'spec_helper'


describe 'provider_generator' do
  before :each do
    FileUtils.rm_rf(provider_spec_dir)
  end

  let(:type_name) do
    'test_type'
  end

  after :each do
    FileUtils.rm_f(generator.provider_name_path) # ensure the file does not exist
  end

  let(:provider_name) do
    'default'
  end

  let(:provider_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'puppet', 'provider', type_name)
  end

  let(:provider_dir) do
    File.join(module_path, 'lib', 'puppet', 'provider', type_name)
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:cli_opts) do
    ARGV.push('-n')
    ARGV.push(provider_name)
    ARGV.push('-t')
    ARGV.push(type_name)
    cli_opts = Retrospec::Puppet::Generators::ProviderGenerator.run_cli(context)
  end

  let(:context) do
    {:module_path => module_path,
     :template_dir => File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates'))}
  end

  let(:generator) do
    Retrospec::Puppet::Generators::ProviderGenerator.new(module_path, cli_opts )
  end

  it 'returns provider dir' do
    expect(generator.provider_dir).to eq(provider_dir)
  end

  it 'returns spec directory' do
    expect(generator.provider_spec_dir).to eq(provider_spec_dir)
  end

  it 'can return provider name' do
    expect(generator.provider_name).to eq(provider_name)
  end

  it 'can generate a provider file' do
    expect(generator.generate_provider_files).to eq(File.join(provider_dir, "#{provider_name}.rb"))
    expect(File.exists?(File.join(provider_dir, "#{provider_name}.rb")))
  end

  it 'can generate a spec file' do
    allow(generator).to receive(:provider_dir).and_return(fixtures_provider_path)
    # allow(generator).to receive(:provider_name_path).and_return(File.join(fixtures_type_path, 'bmc', "ipmitool.rb"))
    expect(generator.generate_provider_spec_files).to eq([File.join(provider_spec_dir, "#{provider_name}_spec.rb")])
  end

  describe 'cli' do

    it 'can run the cli options' do
      # specify the parameters
      expect(cli_opts).to be_an_instance_of Hash
      expect(cli_opts[:name]).to eq(provider_name)
      expect(cli_opts[:type]).to eq(type_name)
    end

  end
end
