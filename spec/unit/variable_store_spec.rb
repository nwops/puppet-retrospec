require 'spec_helper'

describe "variable_store" do
  after :all do
    # enabling the removal slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :all do
    # enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :each do
    @my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'one_resource_module'))
  end

  it 'should initialize' do
    expect(VariableStore.instance.class).to eq(VariableStore)
  end

  it 'should resolve a string' do
    my_retro = Retrospec.new(@my_path)
    test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
    r = Resource.all(test_type).first
    string1 = ObjectSpace.each_object(Puppet::Parser::AST::String).find {|x| x.to_s == "\"value1\"" }
    expect(VariableStore.resolve(string1)).to eq("\"value1\"")
  end

  it 'should resolve a variable' do
    my_retro = Retrospec.new(@my_path)
    test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
    r = Resource.all(test_type).first
    var1 = ObjectSpace.each_object(Puppet::Parser::AST::Variable).find {|x| x.to_s == '$file_name' }
    expect(VariableStore.resolve(var1)).to eq("/tmp/test3")
  end

  it 'should resolve a basic vardef type' do
    my_retro = Retrospec.new(@my_path)
    test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
    VariableStore.populate(test_type)
    vardef1 =  ObjectSpace.each_object(Puppet::Parser::AST::VarDef).find {|x| x.name.value == 'some_var'}
    expect(VariableStore.resolve(vardef1)).to eq("oohhhh")
  end

  it 'should resolve a concat vardef type' do
    my_retro = Retrospec.new(@my_path)
    test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
    VariableStore.populate(test_type)
    vardef2 =  ObjectSpace.each_object(Puppet::Parser::AST::VarDef).find {|x| x.name.value == 'concat_var'}
    expect(VariableStore.resolve(vardef2)).to eq("/tmp/test3/test3183/oohhhh")
  end

  it 'should resolve vardef/concat with parameter value' do
    my_retro = Retrospec.new(@my_path)
    test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
    VariableStore.populate(test_type)
    vardef3 =  ObjectSpace.each_object(Puppet::Parser::AST::VarDef).find {|x| x.name.value == 'cli_modules'}
    expect(VariableStore.resolve(vardef3)).to eq("/etc/hammer/cli.modules.d")
  end

  describe '#add' do
    it 'should store the value correctly' do
      my_retro = Retrospec.new(@my_path)
      test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
      string1 = ObjectSpace.each_object(Puppet::Parser::AST::String).find {|x| x.to_s == "\"value1\"" }
      expect(VariableStore.add(string1, 'blah')).to eq("blah")
      expect(VariableStore.lookup(string1)).to eq('blah')
    end

    it 'variable name should be stored in key with $' do
      keys = VariableStore.instance.store.keys
      expect(keys.include?('$var1')).to eq(true)
    end

    it 'should store vardef as is' do
      my_retro = Retrospec.new(@my_path)
      test_type = my_retro.types.find {|x| x.name == 'one_resource::another_resource'}
      VariableStore.populate(test_type)
    end
  end
end
