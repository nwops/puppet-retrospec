require 'spec_helper'

describe "conditional" do
  after :all do
    # enabling the removal slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :all do
    # enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :each do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'one_resource_module'))
    my_retro = Retrospec.new(my_path)
    @test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
    Resource.all(@test_type)
    conds = Conditional.find_conditionals(@test_type)
    @con = Conditional.new(conds.first, @test_type.arguments)
  end

  it 'should initialize ' do
    expect(@con.class).to eq(Conditional)
  end


  it 'should generate conditional resources' do
    r = Conditional.all(@test_type)
    VariableStore.populate(@test_type)
    expect(r.length).to eq(1)
    expect(r[0].parameters).to eq({"ensure"=>"present"})
    expect(r[0].title).to eq("/tmp/test3/3")
    expect(r[0].type).to eq("file")
  end

  it 'should respond correctly to empty class' do
    my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'zero_resource_module'))
    my_retro = Retrospec.new(my_path)
    test_type = my_retro.types.find {|x| x.name == 'empty_class'}
    expect{Conditional.all(test_type)}.to_not raise_error
  end
end
