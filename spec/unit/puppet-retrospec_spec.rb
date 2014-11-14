require 'spec_helper'
require 'puppet-retrospec'
require 'helpers'
require 'fakefs/safe'

describe "puppet-retrospec" do
  after :all do
    # enabling the removal slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :all do
    # enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
    install_module('puppetlabs-tomcat')
    @path = File.join(fixture_modules_path, 'tomcat')

  end

  before :each do
    ENV['RETROSPEC_ENABLE_LOCAL_TEMPLATES'] = nil
    ENV['RETROSPEC_TEMPLATES_PATH'] = nil
    clean_up_spec_dir(@path)

  end

  it 'should run without errors using new' do
    tomcat = Retrospec.new(@path)
    expect(tomcat.create_files).to eq(true)
    expect(File.exists?(File.join(@path, 'Gemfile'))).to eq(true)
    expect(File.exists?(File.join(@path, '.fixtures.yml'))).to eq(true)
    expect(File.exists?(File.join(@path, 'spec','classes','tomcat_spec.rb'))).to eq(true)
  end

  it 'should create a local templates directory when flag is on' do
    ENV['RETROSPEC_ENABLE_LOCAL_TEMPLATES'] = 'true'
    FakeFS do
      user_directory = Helpers.default_user_template_dir
      FileUtils.mkdir_p(Helpers.gem_template_dir)
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'fixtures_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'resource_spec_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'shared_context.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'spec_helper_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'gemfile.erb'))

      FileUtils.mkdir_p('/modules/tomcat/manifests')
      FileUtils.touch('/modules/tomcat/manifests/init.pp')
      Retrospec.new('/modules/tomcat')
      expect(File.exists?(user_directory)).to eq(true)
      expect(File.exists?(File.join(user_directory, 'gemfile.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'fixtures_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'resource_spec_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'shared_context.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'spec_helper_file.erb'))).to eq(true)
    end
    ENV['RETROSPEC_ENABLE_LOCAL_TEMPLATES'] = nil
    ENV['RETROSPEC_TEMPLATES_PATH'] = nil
  end

  it 'should create the user supplied templates directory when variable is set' do
    ENV['RETROSPEC_TEMPLATES_PATH'] = '/tmp/my_templates'
    FakeFS do
      FileUtils.mkdir_p(Helpers.gem_template_dir)
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'fixtures_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'resource_spec_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'shared_context.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'spec_helper_file.erb'))
      FileUtils.touch(File.join(Helpers.gem_template_dir, 'gemfile.erb'))
      FileUtils.mkdir_p('/modules/tomcat/manifests')
      FileUtils.touch('/modules/tomcat/manifests/init.pp')
      r = Retrospec.new('/modules/tomcat')
      user_directory = r.template_dir
      expect(user_directory).to eq('/tmp/my_templates')
      expect(File.exists?(user_directory)).to eq(true)
      expect(File.exists?(File.join(user_directory, 'fixtures_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'gemfile.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'resource_spec_file.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'shared_context.erb'))).to eq(true)
      expect(File.exists?(File.join(user_directory, 'spec_helper_file.erb'))).to eq(true)
    end
    ENV['RETROSPEC_ENABLE_LOCAL_TEMPLATES'] = nil
    ENV['RETROSPEC_TEMPLATES_PATH'] = nil

  end

  it 'should create proper spec helper file' do
    tomcat = Retrospec.new(@path)
    filepath = File.expand_path(File.join(@path, 'spec', 'spec_helper.rb'))
    path = tomcat.tmp_module_path
    tomcat.safe_create_spec_helper
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create proper shared context file' do
    tomcat = Retrospec.new(@path)
    filepath = File.expand_path(File.join(@path, 'spec', 'shared_contexts.rb'))
    path = tomcat.tmp_module_path
    tomcat.safe_make_shared_context
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create Gemfile file' do
    tomcat = Retrospec.new(@path)
    filepath = File.expand_path(File.join(@path, 'Gemfile'))
    tomcat.safe_create_gemfile
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create Rakefile file' do
    tomcat = Retrospec.new(@path)
    filepath = File.expand_path(File.join(@path, 'Rakefile'))
    tomcat.safe_create_rakefile
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should create proper fixtures file' do
    filepath = File.expand_path(File.join(@path,'.fixtures.yml'))
    FileUtils.rm_f(filepath)  # ensure we have a clean state
    tomcat = Retrospec.new(@path)
    tomcat.safe_create_fixtures_file
    expect(File.exists?(filepath)).to eq(true)
  end

  it 'should not create any files when 0 resources exists' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'zero_resource_module'))
    my_retro = Retrospec.new(my_path)
    Helpers.should_not_receive(:safe_create_file).with(anything,'resource_spec_file.erb')
  end

  it 'should create a temp modules dir' do
    tomcat = Retrospec.new(@path)
    path = tomcat.tmp_modules_dir
    path.should =~ /modules/
  end

  it 'should create a link in the temp modules directory' do
    tomcat = Retrospec.new(@path)
    path = tomcat.tmp_modules_dir
    tomcat.tmp_module_path
    File.exists?(tomcat.tmp_module_path).should eq(true)
    tomcat.tmp_module_path.should eq(File.join(path, tomcat.module_name))
  end

  it 'should create a file from a template' do
    tomcat = Retrospec.new(@path)
    tomcat.safe_create_template_file('.fixtures.yml', 'fixtures_file.erb')
    file_path = File.join(@path,'.fixtures.yml')
    expect(File.exists?(file_path)).to eq(true)
  end

  # it 'should contain a list of parameters in the test' do
  #   tomcat = Retrospec.new(@path)
  #   tomcat.create_files
  #
  # end
  #
  # it 'should retrieve a list of includes' do
  #   # ie. {"includes-class"=>["class1", "class2", "class3", "class6"]}
  #   includes = @retro.included_declarations('spec/fixtures/manifests/includes-class.pp')
  #   includes['includes-class'].should eq(["class1", "class2", "class3", "class6"])
  # end
  #
  # it 'should not include the require statements' do
  #   # ie. {"includes-class"=>["class1", "class2", "class3", "class6"]}
  #   includes = @retro.included_declarations('spec/fixtures/manifests/includes-class.pp')
  #   includes['includes-class'].should_not eq(["class1", "class2", "class3", "class4", "class5", "class6"])
  # end
  #
  #
  # it 'should retrieve a list of define names' do
  #   # ie. [{:filename=>"includes-class", :types=>[{:type_name=>"class", :name=>"includes-class"}]}]
  #   my_retro = Retrospec.new('spec/fixtures/manifests/includes-defines.pp')
  #   classes = my_retro.classes_and_defines('spec/fixtures/manifests/includes-defines.pp')
  #   types = classes.first[:types]
  #   types.first[:type_name].should eq('define')
  #   types.first[:name].should eq("webinstance")
  # end
  #
  #
  # it 'included_declarations should not be nil' do
  #   @retro.included_declarations(@retro.manifest_files.first).length.should >= 1
  # end
  #
  #
  # it 'modules_included should not be nil' do
  #   @retro.modules_included.length.should eq(1)
  # end

end