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
    File.join(module_path, 'spec', 'unit', 'puppet', 'provider')
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
    { :module_path => module_path,
      :template_dir => File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates')) }
  end

  let(:generator) do
    Retrospec::Puppet::Generators::ProviderGenerator.new(module_path, cli_opts)
  end

  it 'returns provider dir' do
    expect(generator.provider_dir).to eq(File.join(module_path, 'lib', 'puppet', 'provider'))
  end

  it 'returns spec directory' do
    expect(generator.provider_spec_dir).to eq(provider_spec_dir)
  end

  it 'can return provider name' do
    expect(generator.provider_name).to eq(provider_name)
  end

  it 'can generate a provider file' do
    expect(generator.generate_provider_files).to eq(File.join(provider_dir, "#{provider_name}.rb"))
    expect(File.exist?(File.join(provider_dir, "#{provider_name}.rb")))
  end

  # because these tests were initially designed to only work with a single type name we will have to go
  # back and rethink how all the names are derived, or possibly structure the fixtures as modules
  it 'can generate a spec file' do
    allow(generator).to receive(:provider_dir).and_return(fixtures_provider_path)
    allow(generator).to receive(:type_dir).and_return(fixtures_type_path)
    files = [File.join(provider_spec_dir, 'bmc', 'ipmitool_spec.rb'), File.join(provider_spec_dir, 'bmcuser', 'ipmitool_spec.rb')]
    expect(generator.generate_provider_spec_files).to eq(files)
  end

  describe 'type_file' do
    before :each do
      allow(generator).to receive(:provider_dir).and_return(fixtures_provider_path)
      allow(generator).to receive(:type_dir).and_return(fixtures_type_path)
    end

    it 'return path of custom type' do
      expect(generator.type_file('bmc')).to eq("#{fixtures_type_path}/bmc.rb")
    end

    it 'return path of core type' do
      expect(generator.type_file('package')).to eq('puppet/type/package')
    end
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
