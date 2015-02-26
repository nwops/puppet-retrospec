require 'spec_helper'

describe "variable_store" do
  let(:instance) {Utilities::PuppetModule.send :new}

  after :all do
    # enabling the removal slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :all do
    @path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'one_resource_module'))
    # enabling the removal of real modules slows down tests, but from time to time we may need to
    FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  end

  before :each do
    @opts = {:module_path => @path, :enable_beaker_tests => false,
             :enable_user_templates => false, :template_dir => nil }
    @module = instance
    @module.module_path = @opts[:module_path]
    @module.create_tmp_module_path(@opts[:module_path])
  end

  it 'should initialize' do
    expect(VariableStore.instance.class).to eq(VariableStore)
  end

  it 'should resolve a string' do
    test_type = @module.types.find {|x| x.name == 'one_resource::another_resource'}
    r = Resource.all(test_type).first
    string1 = ObjectSpace.each_object(Puppet::Parser::AST::String).find {|x| x.to_s == "\"value1\"" }
    expect(VariableStore.resolve(string1)).to eq("\"value1\"")
  end

  it 'should resolve a variable' do
    test_type = @module.types.find {|x| x.name == 'one_resource::another_resource'}
    r = Resource.all(test_type).first
    var1 = ObjectSpace.each_object(Puppet::Parser::AST::Variable).find {|x| x.to_s == '$file_name' }
    expect(VariableStore.resolve(var1)).to eq("/tmp/test3")
  end

  it 'should resolve a basic vardef type' do
    test_type = @module.types.find {|x| x.name == 'one_resource::another_resource'}
    VariableStore.populate(test_type)
    vardef1 = ObjectSpace.each_object(Puppet::Parser::AST::VarDef).find {|x| x.name.value == 'some_var'}
    expect(VariableStore.resolve(vardef1)).to eq("oohhhh")
  end

  it 'should resolve a concat vardef type' do
    test_type = @module.types.find {|x| x.name == 'one_resource::another_resource'}
    VariableStore.populate(test_type)
    vardef2 =  ObjectSpace.each_object(Puppet::Parser::AST::VarDef).find {|x| x.name.value == 'concat_var'}
    expect(VariableStore.resolve(vardef2)).to eq("/tmp/test3/test3183/oohhhh")
  end

  it 'should resolve vardef/concat with parameter value' do
    test_type = @module.types.find {|x| x.name == 'one_resource::another_resource'}
    VariableStore.populate(test_type)
    vardef3 =  ObjectSpace.each_object(Puppet::Parser::AST::VarDef).find {|x| x.name.value == 'cli_modules'}
    expect(VariableStore.resolve(vardef3)).to eq("/etc/hammer/cli.modules.d")
  end

  describe '#add' do
    it 'should store the value correctly' do
      test_type = @module.types.find {|x| x.name == 'one_resource::another_resource'}
      string1 = ObjectSpace.each_object(Puppet::Parser::AST::String).find {|x| x.to_s == "\"value1\"" }
      expect(VariableStore.add(string1, 'blah')).to eq("blah")
      expect(VariableStore.lookup(string1)).to eq('blah')
    end

    it 'variable name should be stored in key with $' do
      keys = VariableStore.instance.store.keys
      expect(keys.include?('$var1')).to eq(true)
    end

    it 'should store vardef as is' do
      test_type = @module.types.find {|x| x.name == 'one_resource::another_resource'}
      VariableStore.populate(test_type)
    end
  end

  describe 'populate' do
    let(:instance) {Utilities::PuppetModule.send :new}

    before :each do

    end
    it 'should load an resolve vars from the parent type' do
      m = instance
      m.module_path = @opts[:module_path]
      m.create_tmp_module_path(@opts[:module_path])
      test_type = m.types.find {|x| x.name == 'one_resource::another_resource'}
      VariableStore.populate(test_type)
      vars = {"$var1"=>"value1",
       "$var2"=>"value2",
       "$file_name"=>"/tmp/test3",
       "$config_base_path"=>"/etc/hammer",
       "$config_set"=>"param1_value",
       "$concat_var"=>"/tmp/test3/test3183/oohhhh",
       "$one_resource::params::param1_var1"=>"param1_value",
       "$one_resource::params::var1"=>"params_class_value1",
       "$one_resource::params::var2"=>"value2",
       "$some_var"=>"oohhhh",
       "$cli_modules"=>"/etc/hammer/cli.modules.d",
       "$inherited_variable"=>"params_class_value1",
      }
      vars.each do |k,v|
        expect(VariableStore.instance.store.keys.include?(k)).to be true
        expect(VariableStore.instance.store[k]).to eq(v)
      end
    end

    xit 'should resolve a fact' do
      #test_type = @module.types.find {|x| x.name == 'one_resource::inherits_params'}
    end

    it 'should resolve a parent parameter' do
      m = instance
      m.module_path = @opts[:module_path]
      m.create_tmp_module_path(@opts[:module_path])
      test_type = m.types.find {|x| x.name == 'one_resource::another_resource'}
      VariableStore.populate(test_type)
      expect(VariableStore.instance.store['$config_set']).to eq('param1_value')

    end

    it 'should resolve a parent variable' do
      m = instance
      m.module_path = @opts[:module_path]
      m.create_tmp_module_path(@opts[:module_path])
      test_type = m.types.find {|x| x.name == 'one_resource::another_resource'}
      VariableStore.populate(test_type)
      expect(VariableStore.instance.store['$inherited_variable']).to eq('params_class_value1')
    end
  end
end
