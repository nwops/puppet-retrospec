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
  end


  describe 'one resource module' do
    before :all do
      @path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'one_resource_module'))
    end

    before :each do
      @opts = {:module_path => @path, :enable_beaker_tests => false,
               :enable_user_templates => false, :template_dir => nil }
    end
    let(:instance) {Utilities::PuppetModule.send :new}

    it 'should initialize correctly scope name' do
      m = instance
      m.module_path = @opts[:module_path]
      m.create_tmp_module_path(@opts[:module_path])
      test_type = m.types.find {|x| x.name == 'one_resource::another_resource'}
      expect(TypeCode.new(test_type).scope_name).to eq('one_resource::another_resource')
      expect(TypeCode.new(test_type).type).to eq(test_type)
    end

    it 'should find all the variables' do
      m = instance
      m.module_path = @opts[:module_path]
      m.create_tmp_module_path(@opts[:module_path])
      test_type = m.types.find {|x| x.name == 'one_resource::another_resource'}
      expect(TypeCode.new(test_type).variables.size).to eq(4)
    end
  end

  describe 'zero module' do
    let(:instance) {Utilities::PuppetModule.send :new}
    it 'should respond correctly when class is empty' do
      my_path = File.expand_path(File.join('spec', 'fixtures', 'fixture_modules', 'zero_resource_module'))
      m = instance
      m.module_path = my_path
      m.create_tmp_module_path(my_path)
      test_type = m.types.find {|x| x.name == 'empty_class'}
      expect{TypeCode.new(test_type).variables}.to_not raise_error
    end
  end

end
