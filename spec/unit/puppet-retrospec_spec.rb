require 'spec_helper'
require 'retrospec'
require 'fakefs/safe'
require 'retrospec/helpers'

describe "puppet-retrospec" do
  after :all do
    # enabling the removal slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :all do
    #enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
    install_module('puppetlabs-tomcat')
    @path = File.join(fixture_modules_path, 'tomcat')

  end

  before :each do
    clean_up_spec_dir(@path)
    @opts = {:module_path => @path, :enable_beaker_tests => false,
             :enable_user_templates => false, :template_dir => nil }
  end

  it 'should run without errors using new' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    expect(tomcat).to be_instance_of(Retrospec)
  end

  it 'should create files without error' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    expect(tomcat.create_files).to eq(true)
    expect(File.exists?(File.join(@path, 'Gemfile'))).to eq(true)
    expect(File.exists?(File.join(@path, 'Rakefile'))).to eq(true)
    expect(File.exists?(File.join(@path, 'spec', 'shared_contexts.rb'))).to eq(true)
    expect(File.exists?(File.join(@path, '.fixtures.yml'))).to eq(true)
    expect(File.exists?(File.join(@path, 'spec','classes','tomcat_spec.rb'))).to eq(true)
  end

  it 'should create acceptance test files' do
    @opts[:enable_beaker_tests] = true
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    spec_path = File.expand_path(File.join(@path, 'spec'))
    tomcat.create_files
    expect(File.exists?(File.join(spec_path, 'spec_helper_acceptance.rb'))).to eq(true)
    expect(File.exists?(File.join(spec_path, 'acceptance'))).to eq(true)
    expect(File.exists?(File.join(spec_path, 'acceptance', 'classes', 'tomcat_spec.rb'))).to eq(true)
    expect(File.exists?(File.join(spec_path, 'acceptance', 'nodesets'))).to eq(true)
    expect(File.exists?(File.join(spec_path, 'acceptance', 'nodesets', 'default.yml'))).to eq(true)

  end

  it 'should not create acceptance test files' do
    clean_up_spec_dir(@path)
    @opts[:enable_beaker_tests] = false
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    spec_path = File.expand_path(File.join(@path, 'spec'))
    tomcat.create_files
    expect(File.exists?(File.join(spec_path, 'spec_helper_acceptance.rb'))).to eq(false)
    expect(File.exists?(File.join(spec_path, 'acceptance'))).to eq(false)
    expect(File.exists?(File.join(spec_path, 'acceptance', 'classes', 'tomcat_spec.rb'))).to eq(false)
    expect(File.exists?(File.join(spec_path, 'acceptance', 'nodesets'))).to eq(false)
    expect(File.exists?(File.join(spec_path, 'acceptance', 'nodesets', 'default.yml'))).to eq(false)
  end

  it 'should create a local templates directory when flag is on' do
    @opts[:enable_user_templates] = true
    FakeFS do
      user_directory = Helpers.default_user_template_dir
      FileUtils.mkdir_p(Helpers.gem_template_dir)
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'fixtures_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'resource_spec_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'shared_context.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'spec_helper_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'gemfile.erb'))
      FileUtils.mkdir_p(File.join(Helpers.gem_template_dir, 'nodesets'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'nodesets', 'default.yml'))
      FileUtils.mkdir_p('/modules/tomcat/manifests')
      FileUtils.touch('/modules/tomcat/manifests/init.pp')
      @opts[:module_path] = '/modules/tomcat'
      Retrospec.new(@opts[:module_path], @opts)
      expect(File.exists?(user_directory)).to eq(true)
      expect(File.exists?(File.join(user_directory, 'gemfile.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'fixtures_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'resource_spec_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'shared_context.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'spec_helper_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'nodesets'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'nodesets', 'default.yml'))).to eq(true)
    end
  end

  it 'should create the user supplied templates directory when variable is set' do
    @opts[:template_dir] = '/tmp/my_templates'
    FakeFS do
      FileUtils.mkdir_p(Helpers.gem_template_dir)
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'fixtures_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'resource_spec_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'shared_context.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'spec_helper_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'gemfile.erb'))
      FileUtils.mkdir_p(File.join(Helpers.gem_template_dir, 'nodesets'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'nodesets', 'default.yml'))
      FileUtils.mkdir_p('/modules/tomcat/manifests')
      FileUtils.touch('/modules/tomcat/manifests/init.pp')
      @opts[:module_path] = '/modules/tomcat'
      r = Retrospec.new(@opts[:module_path], @opts)
      user_directory = r.template_dir
      expect(user_directory).to eq('/tmp/my_templates')
      expect(File.exists?(user_directory)).to eq(true)
      expect(File.exists?(File.join(user_directory, 'fixtures_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'gemfile.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'resource_spec_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'shared_context.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'spec_helper_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'nodesets'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'nodesets', 'default.yml'))).to eq(true)
    end

  end

  it 'should create proper spec helper file' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    filepath = File.expand_path(File.join(@path, 'spec', 'spec_helper.rb'))
    path = tomcat.module_path
    tomcat.safe_create_spec_helper
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create proper shared context file' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    filepath = File.expand_path(File.join(@path, 'spec', 'shared_contexts.rb'))
    path = tomcat.module_path
    tomcat.safe_make_shared_context
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create acceptance spec helper file' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    filepath = File.expand_path(File.join(@path, 'spec', 'spec_helper_acceptance.rb'))
    tomcat.safe_create_acceptance_spec_helper
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create 15 nodesets' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    filepath = File.expand_path(File.join(@path, 'spec', 'acceptance', 'nodesets', 'default.yml'))
    tomcat.safe_create_node_sets
    expect(File.exists?(filepath)).to eq(true)
    expect(Dir.glob(File.expand_path(File.join(@path, 'spec', 'acceptance', 'nodesets', '*.yml'))).length).to eq(15)
  end

  it 'should create Gemfile file' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    filepath = File.expand_path(File.join(@path, 'Gemfile'))
    tomcat.safe_create_gemfile
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create Rakefile file' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    filepath = File.expand_path(File.join(@path, 'Rakefile'))
    tomcat.safe_create_rakefile
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create proper fixtures file' do
    filepath = File.expand_path(File.join(@path,'.fixtures.yml'))
    FileUtils.rm_f(filepath)  # ensure we have a clean state
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    tomcat.safe_create_fixtures_file
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should not create any files when 0 resources exists' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'zero_resource_module'))
    my_retro = Retrospec.new(my_path)
    Helpers.should_not_receive(:safe_create_file).with(anything,'resource_spec_file.erb')
  end

  it 'should create a file from a template' do
    tomcat = Retrospec.new(@opts[:module_path], @opts)
    tomcat.safe_create_template_file('.fixtures.yml', 'fixtures_file.erb')
    file_path = File.join(@path,'.fixtures.yml')
    expect(File.exists?(file_path)).to eq(true)
  end

  describe 'generate_file_path' do

    describe 'classes' do
      it 'should generate a acceptance test path correctly' do
        type = double("type")
        allow(type).to receive(:type).and_return(:hostclass)
        allow(type).to receive(:name).and_return('tomcat::config::server::connector')
        tomcat = Retrospec.new(@opts[:module_path], @opts)
        expect(tomcat.generate_file_path(type, true)).to eq("spec/acceptance/classes/config/server/connector/connector_spec.rb")
      end
      it 'should generate a normal test path correctly' do
        type = double("type")
        allow(type).to receive(:type).and_return(:hostclass)
        allow(type).to receive(:name).and_return('tomcat::config::server::connector')
        tomcat = Retrospec.new(@opts[:module_path], @opts)
        expect(tomcat.generate_file_path(type, false)).to eq("spec/classes/config/server/connector/connector_spec.rb")
      end
    end

    describe 'defines' do
      it 'should generate a acceptance test path correctly' do
        type = double("type")
        allow(type).to receive(:type).and_return(:definition)
        allow(type).to receive(:name).and_return('tomcat::config::server::connector')
        tomcat = Retrospec.new(@opts[:module_path], @opts)
        expect(tomcat.generate_file_path(type, true)).to eq("spec/acceptance/defines/config/server/connector/connector_spec.rb")
      end

      it 'should generate a normal test path correctly' do
        type = double("type")
        allow(type).to receive(:type).and_return(:definition)
        allow(type).to receive(:name).and_return('tomcat::config::server::connector')
        tomcat = Retrospec.new(@opts[:module_path], @opts)
        expect(tomcat.generate_file_path(type, false)).to eq("spec/defines/config/server/connector/connector_spec.rb")
      end
    end
  end

  it 'should generate a test file name correctly' do
     tomcat = Retrospec.new(@opts[:module_path], @opts)
     expect(tomcat.generate_file_name('tomcat::config::server::connector')).to eq('connector_spec.rb')
     expect(tomcat.generate_file_name('tomcat')).to eq('tomcat_spec.rb')
     expect(tomcat.generate_file_name('tomcat::config')).to eq('config_spec.rb')
  end

end