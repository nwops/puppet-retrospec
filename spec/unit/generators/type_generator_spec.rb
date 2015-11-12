require 'spec_helper'

describe 'type generator' do
  before :each do
    FileUtils.rm_rf(type_spec_dir)
    allow(generator).to receive(:type_dir).and_return(fixtures_type_path)
    allow(generator).to receive(:type_name_path).and_return(File.join(module_path, 'lib', 'puppet', 'type', "#{generator.type_name}.rb"))
  end

  after :each do
    FileUtils.rm_rf(File.dirname(File.dirname(generator.type_name_path))) # ensure the file does not exist
    FileUtils.rm_rf(File.dirname(generator.type_spec_dir))
  end

  let(:type_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'puppet', 'type')
  end

  let(:provider_dir) do
    File.join(module_path, 'lib', 'puppet', 'provider')
  end

  let(:provider_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'puppet', 'provider')
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:context) do
    { :name => 'vhost', :providers => [], :properties => %w(config1 config2), :module_path => module_path, :parameters => %w(prop1 prop2),
      :template_dir => File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates')) }
  end

  let(:generator) do
    Retrospec::Puppet::Generators::TypeGenerator.new(module_path, context)
  end

  it 'returns type dir' do
    expect(generator.type_dir).to eq(fixtures_type_path)
  end

  it 'returns module path' do
    expect(generator.type_spec_dir).to eq(type_spec_dir)
  end

  it 'can return type name' do
    expect(generator.type_name).to eq('vhost')
  end

  it 'can generate a type file' do
    expect(generator.generate_type_files).to eq('/Users/cosman/github/puppet-retrospec/spec/fixtures/modules/tomcat/lib/puppet/type/vhost.rb')
    expect(File.exist?(File.join(generator.type_dir, "#{generator.type_name}.rb")))
  end

  it 'can generate a spec file' do
    expect(generator.generate_type_spec_files).to eq(['/Users/cosman/github/puppet-retrospec/spec/fixtures/modules/tomcat/spec/unit/puppet/type/bmc_spec.rb',
                                                      '/Users/cosman/github/puppet-retrospec/spec/fixtures/modules/tomcat/spec/unit/puppet/type/bmcuser_spec.rb'])
  end

  describe 'cli' do
    let(:context) do
      { :module_path => module_path, :template_dir => File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates')) }
    end

    let(:cli_opts) do
      ARGV.push('-p')
      ARGV.push('param_one')
      ARGV.push('param_two')
      ARGV.push('-a')
      ARGV.push('prop_one')
      ARGV.push('prop_two')
      ARGV.push('-n')
      ARGV.push('vhost')
      cli_opts = Retrospec::Puppet::Generators::TypeGenerator.run_cli(context)
    end

    let(:generator) do
      Retrospec::Puppet::Generators::TypeGenerator.new(cli_opts[:module_path], cli_opts)
    end

    after :each do
      FileUtils.rm_rf(File.dirname(File.dirname(generator.type_name_path))) # ensure the file does not exist
      FileUtils.rm_rf(File.dirname(generator.type_spec_dir))
    end

    it 'can run the cli options' do
      # specify the parameters
      expect(cli_opts).to be_an_instance_of Hash
      expect(cli_opts[:properties]).to eq(%w(prop_one prop_two))
      expect(cli_opts[:parameters]).to eq(%w(param_one param_two))
      expect(cli_opts[:name]).to eq('vhost')
    end

    it 'generate type file with correct number of properties' do
      file = generator.generate_type_files
      require file
      t = Puppet::Type.type(:vhost)
      expect(t.properties.count). to eq(3)
    end

    it 'generate type file with correct number of parameters' do
      ARGV.push('-p')
      ARGV.push('param_one')
      ARGV.push('param_two')
      ARGV.push('-a')
      ARGV.push('prop_one')
      ARGV.push('prop_two')
      ARGV.push('-n')
      ARGV.push('vhost')
      opts = Retrospec::Puppet::Generators::TypeGenerator.run_cli(context)
      t = Retrospec::Puppet::Generators::TypeGenerator.new(opts[:module_path], opts)
      file = generator.generate_type_files
      require file
      t = Puppet::Type.type(:vhost)
      expect(t.parameters.count). to eq(2)
    end

    it 'generate type' do
      ARGV.push('-p')
      ARGV.push('param_one')
      ARGV.push('param_two')
      ARGV.push('-a')
      ARGV.push('prop_one')
      ARGV.push('prop_two')
      ARGV.push('-n')
      ARGV.push('vhost')
      ARGV.push('--providers')
      ARGV.push('default1')
      ARGV.push('default2')
      opts = Retrospec::Puppet::Generators::TypeGenerator.run_cli(context)
      t = Retrospec::Puppet::Generators::TypeGenerator.new(opts[:module_path], opts)
      file = t.generate_type_files
      require file
      t = Puppet::Type.type(:vhost)
      expect(File.exist?(file)).to eq(true)
    end

    it 'generate providers' do
      ARGV.push('-p')
      ARGV.push('param_one')
      ARGV.push('param_two')
      ARGV.push('-a')
      ARGV.push('prop_one')
      ARGV.push('prop_two')
      ARGV.push('-n')
      ARGV.push('vhost')
      ARGV.push('--providers')
      ARGV.push('default1')
      ARGV.push('default2')
      opts = Retrospec::Puppet::Generators::TypeGenerator.run_cli(context)
      t = Retrospec::Puppet::Generators::TypeGenerator.new(opts[:module_path], opts)
      file = t.generate_type_files
      p_vhost = File.join(provider_dir, 'vhost')
      expect(File.exist?(File.join(p_vhost, 'default1.rb'))).to eq(true)
      expect(File.exist?(File.join(p_vhost, 'default2.rb'))).to eq(true)
      expect(t.context.providers).to eq(%w(default1 default2))
    end
  end
end
