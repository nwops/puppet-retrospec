require 'spec_helper'
require 'retrospec/type_code'

describe "type_code" do
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
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'one_resource_module'))
    @my_retro = Retrospec.new(my_path)
    @test_type = @my_retro.types.find {|x| x.name == 'one_resource::another_resource'}

  end
  it 'should initialize correctly scope name' do
    expect(TypeCode.new(@test_type).scope_name).to eq('one_resource::another_resource')
    expect(TypeCode.new(@test_type).type).to eq(@test_type)
  end

  it 'should find all the variables' do
    expect(TypeCode.new(@test_type).variables.size).to eq(3)
  end

  it 'should respond correctly when class is empty' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'zero_resource_module'))
    my_retro = Retrospec.new(my_path)
    test_type = my_retro.types.find {|x| x.name == 'empty_class'}
    expect{TypeCode.new(test_type).variables}.to_not raise_error
  end
end
