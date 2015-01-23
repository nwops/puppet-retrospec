require 'spec_helper'
require 'retrospec/resource'

describe "resource" do
  after :all do
    # enabling the removal slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :all do
    # enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
    @path = File.join(fixture_modules_path, 'tomcat')


  end

  before :each do
    clean_up_spec_dir(@path)
    @opts = {:module_path => @path, :enable_beaker_tests => false,
             :enable_user_templates => false, :template_dir => nil }

  end

  it 'should initialize with one resource' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'one_resource_module'))
    my_retro = Retrospec.new(my_path)
    r = Resource.all(my_retro.types.find {|x| x.name == 'one_resource'})
    expect(r.length).to eq(1)
    expect(r[0].parameters).to eq({"ensure"=>"present"})
    expect(r[0].title).to eq("/tmp/test")
    expect(r[0].type).to eq("file")
  end

  it 'should initialize with two resources' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'one_resource_module'))
    my_retro = Retrospec.new(my_path)
    test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
    VariableStore.populate(test_type)
    r = Resource.all(test_type)
    expect(r.length).to eq(2)
    expect(r[0].parameters).to eq({"ensure"=>"present"})
    expect(r[0].title).to eq("/tmp/test2")
    expect(r[0].type).to eq("file")
    expect(r[1].parameters).to eq({"ensure"=>"present","content" => "/tmp/test3/test3183/oohhhh"})
    expect(r[1].title).to eq("/tmp/test3")
    expect(r[1].type).to eq("file")
  end

  it 'should return resources' do
    test_module = Retrospec.new(@opts[:module_path], @opts)
    test_type = test_module.types[0]
    expect(Resource.all(test_type.code)).to eq([])
  end

  it 'can process an empty class' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'zero_resource_module'))
    my_retro = Retrospec.new(my_path)
    r = Resource.all(my_retro.types.find {|x| x.name == 'empty_class'})
    expect(r.size).to eq(0)
  end
end
