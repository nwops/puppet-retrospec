require 'spec_helper'
require 'puppet-retrospec'
require 'helpers'
require 'pry'
describe "puppet-retrospec" do

  before :each do
    @retro = Retrospec.new('spec/fixtures/*.pp')


  end

  it 'should return a list of files' do
    @retro.files.length.should be(2)
  end

  it 'should retrieve a list of includes' do
    # ie. {"includes-class"=>["class1", "class2", "class3", "class6"]}
     includes = @retro.included_declarations(['spec/fixtures/includes-class.pp'])
     includes['includes-class'].should eq(["class1", "class2", "class3", "class6"])
  end

  it 'should not include the require statements' do
    # ie. {"includes-class"=>["class1", "class2", "class3", "class6"]}
    includes = @retro.included_declarations(['spec/fixtures/includes-class.pp'])
    includes['includes-class'].should_not eq(["class1", "class2", "class3", "class4", "class5", "class6"])
  end

  it 'should retrieve a list of class names' do
    # ie. [{:filename=>"includes-class", :types=>[{:type_name=>"class", :name=>"includes-class"}]}]
    classes = @retro.classes_and_defines(['spec/fixtures/includes-class.pp'])
    types = classes.first[:types]
    types.first[:type_name].should eq('class')
    types.first[:name].should eq("includes-class")
  end

  it 'should retrieve a list of define names' do
    # ie. [{:filename=>"includes-class", :types=>[{:type_name=>"class", :name=>"includes-class"}]}]
    classes = @retro.classes_and_defines(['spec/fixtures/includes-defines.pp'])
    types = classes.first[:types]
    types.first[:type_name].should eq('define')
    types.first[:name].should eq("webinstance")
  end

  it 'should create resource spec files' do
    #Helpers.should_receive(:get_module_name).and_return('mymodule')
    Helpers.should_receive(:safe_mkdir).with('spec/classes').twice
    Helpers.should_receive(:safe_mkdir).with('spec/defines').twice
    Helpers.should_receive(:safe_create_file).with(an_instance_of(String), an_instance_of(String)).twice
    @retro.safe_create_resource_spec_files('resource-spec_file.erb')
  end

  it 'should create proper spec helper file' do
    #Helpers.should_receive(:get_module_name).and_return('mymodule')
    Helpers.should_receive(:safe_create_file).with('spec/spec_helper.rb',anything).once
    @retro.safe_create_spec_helper('spec_helper_file.erb')

  end

  it 'should return the correct module name' do
    Helpers.should_receive(:get_module_name).and_return('mymodule')
    @retro.module_name.should eq('mymodule')
  end

  it 'should create proper fixtures file' do
    #Helpers.should_receive(:get_module_name).and_return('mymodule')
    Helpers.should_receive(:safe_create_file).with('.fixtures.yml',anything).once
    @retro.safe_create_fixtures_file('fixtures_file.erb')

  end

  it 'included_declarations should not be nil' do
    @retro.included_declarations.length.should >= 1
  end

  it 'classes_and_defines should not be nil' do
    @retro.classes_and_defines.length.should >= 1
  end

  it 'module_name should not be nil' do
    Helpers.should_receive(:get_module_name).and_return('mymodule')
    @retro.module_name.should_not be_nil
  end

  it 'modules_included should not be nil' do
    @retro.modules_included.length.should eq(1)
  end

end