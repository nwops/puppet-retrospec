require 'spec_helper'
require 'fakefs/safe'

describe 'puppet-retrospec' do
  after :all do
    # enabling the removal slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  let(:template_dir) do
    retrospec_templates_path
  end

  let(:global_config) do
    { 'author' => 'Corey Osman' }
  end

  let(:plugin_config) do
    {
      # 'plugins::puppet::template_dir' => '/Users',
      # 'plugins::puppet::templates::url' => '',
      # 'plugins::puppet::templates::ref'  => '',
      # 'plugins::puppet::enable_future_parser' => '',
      # 'plugins::puppet::enable_beaker_tests' => '',
      # 'plugins::puppet::namespace' => '',
      # 'plugins::puppet::auto_create' => '',
    }
  end

  let(:global_opts) do
    opts.merge(plugin_config)
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:module_spec_path) do
    File.join(module_path, 'spec')
  end

  let(:path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  before :all do
    # enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
    install_module('puppetlabs-tomcat')
  end

  before :each do
    clean_up_module_dir(path)
    @opts = { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
              :enable_user_templates => false, :template_dir => template_dir }
  end

  let(:opts) do
    {
      :module_path => module_path,
      :enable_beaker_tests => false,
      :name => 'name-test123',
      :enable_user_templates => false,
      :template_dir => template_dir
    }
  end

  it 'should run without errors using new' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    expect(tomcat).to be_instance_of(Retrospec::Plugins::V1::Puppet)
  end

  it 'should set the parser to future' do
    opts = { :module_path => path, :enable_beaker_tests => false,
             :enable_user_templates => false, :template_dir => nil, :enable_future_parser => true }
    tomcat = Retrospec::Plugins::V1::Puppet.new(opts[:module_path], opts)
    tomcat.post_init
    expect(tomcat.context.instance.future_parser).to eq(true)
  end


  it 'should create files without error' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    tomcat.create_files
    expect(File.exist?(File.join(path, 'Gemfile'))).to eq(true)
    expect(File.exist?(File.join(path, 'Rakefile'))).to eq(true)
    expect(File.exist?(File.join(path, 'spec', 'spec_helper.rb'))).to eq(true)
    expect(File.exist?(File.join(path, '.travis.yml'))).to eq(true)
    expect(File.exist?(File.join(path, 'spec', 'shared_contexts.rb'))).to eq(true)
    expect(File.exist?(File.join(path, '.fixtures.yml'))).to eq(true)
    expect(File.exist?(File.join(path, 'spec', 'classes', 'tomcat_spec.rb'))).to eq(true)
  end

  it 'should create acceptance test files' do
    @opts[:enable_beaker_tests] = true
    tomcat = Retrospec::Plugins::V1::Puppet.new(@opts[:module_path], @opts)
    tomcat.post_init
    spec_path = File.expand_path(File.join(path, 'spec'))
    tomcat.create_files
    expect(File.exist?(File.join(spec_path, 'spec_helper_acceptance.rb'))).to eq(true)
    expect(File.exist?(File.join(spec_path, 'acceptance'))).to eq(true)
    expect(File.exist?(File.join(spec_path, 'acceptance', 'classes', 'tomcat_spec.rb'))).to eq(true)
    expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets'))).to eq(true)
    expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets', 'default.yml'))).to eq(true)
  end

  it 'should not create acceptance test files' do
    clean_up_module_dir(path)
    @opts[:enable_beaker_tests] = false
    tomcat = Retrospec::Plugins::V1::Puppet.new(@opts[:module_path], @opts)
    tomcat.post_init
    spec_path = File.expand_path(File.join(path, 'spec'))
    tomcat.create_files
    expect(File.exist?(File.join(spec_path, 'spec_helper_acceptance.rb'))).to eq(false)
    expect(File.exist?(File.join(spec_path, 'acceptance'))).to eq(true)
    expect(File.exist?(File.join(spec_path, 'acceptance', 'classes', 'tomcat_spec.rb'))).to eq(false)
    expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets'))).to eq(false)
    expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets', 'default.yml'))).to eq(false)
    expect(File.exist?(File.join(module_path, 'Gemfile'))).to eq(true)
    expect(File.exist?(File.join(module_path, 'Rakefile'))).to eq(true)
    expect(File.exist?(File.join(module_path, 'spec', 'spec_helper.rb'))).to eq(true)
    expect(File.exist?(File.join(module_path, '.travis.yml'))).to eq(true)
    expect(File.exist?(File.join(module_path, 'spec', 'shared_contexts.rb'))).to eq(true)
    expect(File.exist?(File.join(module_path, '.fixtures.yml'))).to eq(true)
    expect(File.exist?(File.join(module_path, 'spec', 'classes', 'tomcat_spec.rb'))).to eq(true)
  end

  describe 'acceptance tests' do
    context 'should' do
      let(:plugin_config) do
        {
           :enable_beaker_tests => true
        }
      end
      it 'create acceptance test files' do
        opts[:enable_beaker_tests] = true
        tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
        tomcat.post_init
        spec_path = File.expand_path(File.join(module_path, 'spec'))
        tomcat.create_files
        expect(File.exist?(File.join(spec_path, 'spec_helper_acceptance.rb'))).to eq(true)
        expect(File.exist?(File.join(spec_path, 'acceptance'))).to eq(true)
        expect(File.exist?(File.join(spec_path, 'acceptance', 'classes', 'tomcat_spec.rb'))).to eq(true)
        expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets'))).to eq(true)
        expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets', 'default.yml'))).to eq(true)
      end

      it 'create 15 nodesets' do
        tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
        tomcat.post_init
        filepath = File.expand_path(File.join(module_path, 'spec', 'acceptance', 'nodesets', 'default.yml'))
        tomcat.safe_create_module_files
        expect(File.exist?(filepath)).to eq(true)
        expect(Dir.glob(File.expand_path(File.join(module_path, 'spec', 'acceptance', 'nodesets', '*.yml'))).length).to eq 15
      end
    end
    context 'should not' do
      let(:plugin_config) do
        {
           :enable_beaker_tests => false
        }
      end

      it 'create acceptance test files' do
        clean_up_spec_dir(module_path)
        opts[:enable_beaker_tests] = false
        tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
        tomcat.post_init
        spec_path = File.expand_path(File.join(module_path, 'spec'))
        tomcat.create_files
        expect(File.exist?(File.join(spec_path, 'spec_helper_acceptance.rb'))).to eq(false)
        expect(File.exist?(File.join(spec_path, 'acceptance'))).to eq(true)
        expect(File.exist?(File.join(spec_path, 'acceptance', 'classes', 'tomcat_spec.rb'))).to eq(false)
        expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets'))).to eq(false)
        expect(File.exist?(File.join(spec_path, 'acceptance', 'nodesets', 'default.yml'))).to eq(false)
      end

      it 'create acceptance spec helper file' do
        tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
        tomcat.post_init
        filepath = File.expand_path(File.join(module_path, 'spec', 'spec_helper_acceptance.rb'))
        tomcat.safe_create_module_files
        expect(File.exist?(filepath)).to eq(true)
      end
      it 'create acceptance spec helper file' do
        filepath = File.expand_path(File.join(module_path, 'spec', 'spec_helper_acceptance.rb'))
        tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
        tomcat.post_init
        tomcat.safe_create_module_files
        expect(File.exist?(filepath)).to eq(false)
      end
    end

  end

  it 'should create proper spec helper file' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    filepath = File.expand_path(File.join(module_path, 'spec', 'spec_helper.rb'))
    tomcat.safe_create_module_files
    path = tomcat.module_path
    expect(File.exist?(filepath)).to eq(true)
  end

  it 'should create proper shared context file' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    filepath = File.expand_path(File.join(module_path, 'spec', 'shared_contexts.rb'))
    tomcat.safe_create_module_files
    expect(File.exist?(filepath)).to eq(true)
  end

  it 'should produce hiera data' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    filepath = File.expand_path(File.join(module_path, 'spec', 'shared_contexts.rb'))
    tomcat.safe_create_module_files
    path = tomcat.module_path
    expect(tomcat.context.all_hiera_data).to eq('tomcat::catalina_home' => nil,
                                                'tomcat::user' => nil,
                                                'tomcat::group' => nil,
                                                'tomcat::install_from_source' => nil,
                                                'tomcat::purge_connectors' => nil,
                                                'tomcat::purge_realms' => nil,
                                                'tomcat::manage_user' => nil,
                                                'tomcat::manage_group' => nil
                                               )

    expect(File.read(filepath)).to include('#"tomcat::catalina_home" => \'\',')
  end

  it 'should create acceptance spec helper file' do
    opts = { :module_path => path, :enable_beaker_tests => true,
             :template_dir => template_dir }
    tomcat = Retrospec::Plugins::V1::Puppet.new(@opts[:module_path], opts)
    tomcat.post_init
    filepath = File.expand_path(File.join(path, 'spec', 'spec_helper_acceptance.rb'))
    tomcat.safe_create_module_files
    expect(File.exist?(filepath)).to eq(true)
  end

  it 'should not create acceptance spec helper file' do
    opts = { :module_path => path, :enable_beaker_tests => false,
             :template_dir => template_dir }
    filepath = File.expand_path(File.join(path, 'spec', 'spec_helper_acceptance.rb'))
    tomcat = Retrospec::Plugins::V1::Puppet.new(@opts[:module_path], opts)
    tomcat.post_init
    tomcat.safe_create_module_files
    expect(File.exist?(filepath)).to eq(false)
  end

  it 'should create 15 nodesets' do
    opts = { :module_path => path, :enable_beaker_tests => true,
             :template_dir => template_dir }
    tomcat = Retrospec::Plugins::V1::Puppet.new(@opts[:module_path], opts)
    tomcat.post_init
    filepath = File.expand_path(File.join(path, 'spec', 'acceptance', 'nodesets', 'default.yml'))
    tomcat.safe_create_module_files
    expect(File.exist?(filepath)).to eq(true)
    expect(Dir.glob(File.expand_path(File.join(path, 'spec', 'acceptance', 'nodesets', '*.yml'))).length).to eq 15
  end

  it 'should create Gemfile file' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    filepath = File.expand_path(File.join(module_path, 'Gemfile'))
    tomcat.safe_create_module_files
    expect(File.exist?(filepath)).to eq(true)
  end

  it 'should create Rakefile file' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    filepath = File.expand_path(File.join(module_path, 'Rakefile'))
    tomcat.safe_create_module_files
    expect(File.exist?(filepath)).to eq(true)
  end

  it 'should create proper fixtures file' do
    filepath = File.expand_path(File.join(module_path, '.fixtures.yml'))
    FileUtils.rm_f(filepath) # ensure we have a clean state
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    tomcat.safe_create_module_files
    expect(File.exist?(filepath)).to eq(true)
  end

  it 'should not create any files when 0 resources exists' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'zero_resource_module'))
    my_retro = Retrospec::Plugins::V1::Puppet.new(my_path, global_opts)
    my_retro.should_not_receive(:safe_create_file).with(anything, 'resource_spec_file.erb')
  end

  it 'should create a file from a template' do
    tomcat = Retrospec::Plugins::V1::Puppet.new(module_path, global_opts)
    tomcat.post_init
    file_path = File.join(module_path, '.fixtures.yml')
    template_file = File.join(tomcat.template_dir, 'module_files', '.fixtures.yml.retrospec.erb')
    tomcat.safe_create_template_file(file_path, template_file, tomcat.context)
    expect(File.exist?(file_path)).to eq(true)
  end
end
