require 'spec_helper'

describe 'ModuleDataGenerator' do
  let(:cli_opts) do
    cli_opts = Retrospec::Puppet::Generators::ModuleDataGenerator.run_cli(context, opts)
    cli_opts[:puppet_context] = puppet_context
    cli_opts
  end

  let(:context) do
    { :module_path => module_path,
      :template_dir => retrospec_templates_path }
  end

  let(:puppet_context) do
    # before we validate the module directory we should ensure the module exists by creating it
    # validation also occurs when setting the module path
    # these are required because the puppet module creates a singleton with some cached values
    Utilities::PuppetModule.instance.module_dir_name = File.basename(module_path)
    Utilities::PuppetModule.instance.module_name = File.basename(module_path)
    Utilities::PuppetModule.instance.module_path = module_path
    Utilities::PuppetModule.create_tmp_module_path # this is required to finish initialization
    # setting the context is required to make other methods below work.  #TODO lazy create the context
    ::Retrospec::Puppet::SpecObject.new(module_path, Utilities::PuppetModule.instance, context)
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::ModuleDataGenerator.new(module_path, cli_opts)
  end

  before(:each) do
    FileUtils.rm_rf(File.join(module_path, 'data')) # ensure the file does not exist
    FileUtils.rm_f(File.join(module_path, 'hiera.yaml')) # ensure the file does not exist
    FileUtils.rm_rf(File.join(module_path, 'functions')) # ensure the file does not exist
    FileUtils.rm_rf(File.join(module_path, 'lib', 'puppet', 'functions')) # ensure the file does not exist

    Utilities::PuppetModule.instance.module_dir_name = File.basename(module_path)
    Utilities::PuppetModule.instance.module_name = File.basename(module_path)
    Utilities::PuppetModule.instance.module_path = module_path
    Utilities::PuppetModule.create_tmp_module_path # this is required to finish initialization
  end

  describe 'hiera' do
    let(:opts) do
      ['-b', 'hiera']
    end
    it 'works with hiera' do
      generator.run
      expect(File.exist?(File.join(module_path, 'data'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'functions'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
    end

    it 'works with hiera data' do
      generator.run
      output = File.read(File.join(module_path, 'data', 'common.yaml'))
      expect(output).to match(/tomcat/)
      expect(File.exist?(File.join(module_path, 'data'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'functions'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
    end
  end

  describe 'data_hash native' do
    let(:opts) do
      ['-b', 'data_hash', '-n', 'my_custom', '-t', 'native']
    end
    it 'works with function' do
      generator.run
      expect(File.exist?(File.join(module_path, 'functions', 'my_custom.pp'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'data'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'os'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
      file_data = File.readlines(File.join(module_path, 'functions', 'my_custom.pp'))
      expect(file_data.grep(/tomcat::my_custom/)).to eq(["function tomcat::my_custom(\n"])
    end
  end

  describe 'data_dig native' do
    let(:opts) do
      ['-b', 'data_dig', '-n', 'my_custom', '-t', 'native']
    end
    it 'works with function' do
      generator.run
      expect(File.exist?(File.join(module_path, 'functions', 'my_custom.pp'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'data'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'os'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
      file_data = File.readlines(File.join(module_path, 'functions', 'my_custom.pp'))
      expect(file_data.grep(/tomcat::my_custom/)).to eq(["function tomcat::my_custom(\n"])
    end
  end

  describe 'lookup_key native' do
    let(:opts) do
      ['-b', 'lookup_key', '-n', 'my_custom', '-t', 'native']
    end
    it 'works with function' do
      generator.run
      expect(File.exist?(File.join(module_path, 'functions', 'my_custom.pp'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'data'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'os'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
      file_data = File.readlines(File.join(module_path, 'functions', 'my_custom.pp'))
      expect(file_data.grep(/tomcat::my_custom/)).to eq(["function tomcat::my_custom(\n"])
    end
  end

  describe 'data_hash ruby' do
    let(:opts) do
      ['-b', 'data_hash', '-n', 'my_custom', '-t', 'v4']
    end
    it 'works with function' do
      generator.run
      expect(File.exist?(File.join(module_path, 'lib', 'puppet', 'functions', 'my_custom.rb'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'data'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'os'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
      file_data = File.readlines(File.join(module_path, 'lib', 'puppet', 'functions', 'my_custom.rb'))
      expect(file_data.grep(/tomcat::my_custom/)).to eq(["Puppet::Functions.create_function(:\"tomcat::my_custom\") do\n"])
      expect(file_data.grep(/dispatch :my_custom/)).to eq(["  dispatch :my_custom do\n"])
      expect(file_data.grep(/def my_custom/)).to eq(["  def my_custom(options, context)\n"])
    end
  end

  describe 'data_dig ruby' do
    let(:opts) do
      ['-b', 'data_dig', '-n', 'my_custom', '-t', 'v4']
    end
    it 'works with function' do
      generator.run
      expect(File.exist?(File.join(module_path, 'lib', 'puppet', 'functions', 'my_custom.rb'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'data'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'os'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
      file_data = File.readlines(File.join(module_path, 'lib', 'puppet', 'functions', 'my_custom.rb'))
      expect(file_data.grep(/tomcat::my_custom/)).to eq(["Puppet::Functions.create_function(:\"tomcat::my_custom\") do\n"])
      expect(file_data.grep(/dispatch :my_custom/)).to eq(["  dispatch :my_custom do\n"])
      expect(file_data.grep(/def my_custom/)).to eq(["  def my_custom(segments, options, context)\n"])
    end
  end

  describe 'lookup_key ruby' do
    let(:opts) do
      ['-b', 'lookup_key', '-n', 'my_custom', '-t', 'v4']
    end
    it 'works with function' do
      generator.run
      expect(File.exist?(File.join(module_path, 'lib', 'puppet', 'functions', 'my_custom.rb'))).to eq(true)
      expect(File.exist?(File.join(module_path, 'data'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'os'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'data', 'common.yaml'))).to eq(false)
      expect(File.exist?(File.join(module_path, 'hiera.yaml'))).to eq(true)
      file_data = File.readlines(File.join(module_path, 'lib', 'puppet', 'functions', 'my_custom.rb'))
      expect(file_data.grep(/tomcat::my_custom/)).to eq(["Puppet::Functions.create_function(:\"tomcat::my_custom\") do\n"])
      expect(file_data.grep(/dispatch :my_custom/)).to eq(["  dispatch :my_custom do\n"])
      expect(file_data.grep(/def my_custom/)).to eq(["  def my_custom(key, options, context)\n"])
    end
  end
end
