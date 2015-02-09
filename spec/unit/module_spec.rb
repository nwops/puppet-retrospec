require 'spec_helper'

describe 'Utilities::Module' do

  before :each do
    clean_up_spec_dir(@path)
    @opts = {:module_path => @path, :enable_beaker_tests => false,
             :enable_user_templates => false, :template_dir => nil }
    @module = Utilities::PuppetModule.instance
    @module.module_path = @opts[:module_path]

  end

  before :all do
    # enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
    install_module('puppetlabs-tomcat')
    @path = File.join(fixture_modules_path, 'tomcat')
  end

  it 'should create an instance' do
    expect(@module).to be_instance_of(Utilities::PuppetModule)
  end

  it 'should create tmp module path' do
    expect(File.exists?(@module.tmp_modules_dir)).to be true
  end

  it 'should create a temp modules dir' do
    tomcat_path = Utilities::PuppetModule.create_tmp_module_path
    expect(tomcat_path).to match(/modules/)
  end

  it 'should create a temp modules dir' do
    tomcat_path = @module.create_tmp_module_path(@opts[:module_path])
    expect(tomcat_path).to match(/modules/)
    expect(File.exists?(tomcat_path)).to be true
  end

  it 'should set the module path' do
    expect(@module.module_path).to eq(@opts[:module_path])
  end

  it 'should create a link in the temp modules directory' do
    tmp_path = @module.create_tmp_module_path(@opts[:module_path])
    expect(File.exists?(tmp_path)).to eq(true)
    expect(tmp_path).to eq(File.join(@module.tmp_modules_dir, @module.module_name))
  end

  it 'should find types' do
    expect(@module.types).to be_instance_of(Array)
    expect(@module.types.map {|t| t.name}.length).to eq(14)
  end

end