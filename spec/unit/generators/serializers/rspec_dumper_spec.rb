require 'spec_helper'
require 'retrospec/plugins/v1/plugin/generators/serializers/rspec_dumper'

describe 'rspec_serializer' do

  let(:sample_file) do
    File.join(fixtures_path, 'manifests', 'sql.pp')
  end

  let(:module_path) do
    sample_module_path
  end

  let(:hostclass_spec_file) do
    path = File.join(module_path, 'spec', 'classes', 'testclass_spec.rb')
  end

  let(:ast) do
    parser = ::Puppet::Pops::Parser::EvaluatingParser.new
    result = parser.parse_file(sample_file)
    ast = result.current
  end

  let(:store) do
    {
      "$backup_root_dir" => {:value=>"c:\\backup", :type=>:parameter},
       "$features_location" => {:value=>:undef, :type=>:parameter},
       "$install_account_passwords" => {:value=>{}, :type=>:parameter},
       "$install_accounts" => {:value=>{}, :type=>:parameter},
       "$install_options" => {:value=>{}, :type=>:parameter},
       "$install_type" => {:value=>"default", :type=>:parameter},
       "$instance_name" => {:value=>"MSSQLSERVER", :type=>:parameter},
       "$source" => {:value=>:undef, :type=>:parameter},
       "$sql::backup_root_dir" => {:value=>"c:\\backup", :type=>:parameter},
       "$sql::features_location" => {:value=>:undef, :type=>:parameter},
       "$sql::install_account_passwords" => {:value=>{}, :type=>:parameter},
       "$sql::install_accounts" => {:value=>{}, :type=>:parameter},
       "$sql::install_options" => {:value=>{}, :type=>:parameter},
       "$sql::install_type" => {:value=>"default", :type=>:parameter},
       "$sql::instance_name" => {:value=>"MSSQLSERVER", :type=>:parameter},
       "$sql::source" => {:value=>:undef, :type=>:parameter},
       "$sql::ssdt_install_options" => {:value=>{}, :type=>:parameter},
       "$ssdt_install_options" => {:value=>{}, :type=>:parameter},
       "$value" => {:value=>"$value", :type=>:top_scope}
    }
  end
  let(:hostclass_body) do
    hostclass.body
  end

  let(:resource_bodies) do
    [resource_body]
  end

  let(:resource_body) do
    resource_exp.eContents.last
  end

  let(:case_exp) do
    hostclass_body.statements.first
  end

  let(:case_opt) do
    case_exp.options.first
  end

  let(:resource_exp) do
     relationship_exp.eContents.last
  end

  let(:relationship_exp) do
    hostclass_body.statements.last
  end

  let(:parameters) do
    hostclass.parameters
  end

  let(:hostclass) do
    ast.eContents.first
  end

  let(:serializer) do
    class_def = ast.body
    parameters = class_def.parameters
    dumper = Retrospec::Puppet::RspecDumper.new
  end

  let(:parameter_data) do
    File.read(File.join(fixtures_path, 'parameters.txt'))
  end

  let(:rel_data) do
    "it do\n  is_expected.to contain_class('sql2014::install')\n    .with(\n      \"sql_install_flags\" =>\n      \"instance_name\" =>\n      \"installer_source\" =>\n      \"features_location\" =>\n      \"ssdt_options\" =>\n      \n    )\nend\n\nit do\n  is_expected.to contain_sql2014__backup($instance_name)\n    .with(\n      \"backup_root_dir\" =>\n      \n    )\nend\n\nit do\n  is_expected.to contain_class('sql2014::login')\nend\n"
  end

  describe 'should generate content for' do
    before(:each) do
      # prime the var store
      serializer.dump(parameters)
      serializer.dump(ast)
    end
    it 'parameters' do
      expect(serializer.dump(parameters)).to eq(parameter_data)
    end

    it 'and comment out default parameters' do
      expect(serializer.dump(parameters.last)).to match(/\#{1}/)
    end

    it 'parameter value should end with a comma' do
      parameters.each do |p|
        expect(serializer.dump(p)).to match(/,$/)
      end
    end

    it 'and force user to fill out parameter' do
      expect(serializer.dump(parameters.first)).to match(/[^#]{1}/)
    end

    it 'should generate the content for an ast' do
      content = File.read(File.join(fixtures_path, 'spec_test_file.txt'))
      expect(serializer.dump(ast)).to eq(content)
    end
    # it 'should generate the content for a host class' do
    #   expect(serializer.dump(hostclass)).to eq('')
    # end

    it 'host class' do
      content = File.read(File.join(fixtures_path, 'host_class_test.txt'))
      expect(serializer.dump(hostclass_body)).to eq(content)
    end
    #
    it 'case option' do
      # test = serializer.dump(case_exp.test)
      # ls, exp = case_exp.options.first.eContents
      # case_exp.options.first.eContents
      # options = case_exp.options
#      data = "context 'custom' do\n  context blah do\n    it { is_expected.to call(fail).with('Install type: default specified but no install options given')} \n  end\nend"
      data = ''
      expect(serializer.dump(case_opt)).to match(/context\ 'custom'\ do\n/)
      expect(serializer.dump(case_opt)).to eq(data)
    end

    it 'if_expr' do
      if_expr = case_opt.then_expr.statements.first
      data = "context '$install_options is nil' do\n  it { is_expected.to call(fail).with('Install type: default specified but no install options given')} \nend"
      expect(serializer.dump(if_expr)).to eq(data)
    end
    #
    it 'when a variable assignement occurs, record the variable' do
      fail('not implemented')
    end

    it 'CallNamedFunctionExpression' do
      if_expr = case_opt.then_expr.statements.first
      func_expr = if_expr.test
      expect(serializer.dump(func_expr)).to eq('it { is_expected.to call(empty).with($install_options) }')
    end

    it 'assign_expr' do
      assign_expr = case_opt.then_expr.statements.last
      expect(serializer.dump(assign_expr)).to eq('')
    end

    it 'assign_expr' do
      assign_expr = case_opt.then_expr.statements.last
      expect(serializer.var_store.keys.include?('${}')).to eq(false)
    end

    describe 'case_expr' do
      let(:data) do
        "describe 'default' do\n  let(:params) do\n    params.merge({})\n  end\n  let(:facts) do\n  \n  end\n  context 'custom' do\n    \n    context 'empty {}' do\n      it { is_expected.to call(fail).with('Install type: ','default',' specified but no install options given')} \n    end\n    \n    \n  end\n  context :default do\n    \n    \n    \n    \n    \n  end"
      end

      it 'should return correct describe block' do
        expect(serializer.dump(case_exp)).to eq(data)
      end
    end

    describe 'resource body' do
      it 'returns a resource_body containing with() when contain attributes' do
        r_b = relationship_exp.eContents.first.eContents.first
        expect(serializer.dump(r_b)).to match(/\with\(/)
      end

      it 'returns a resource_body not containing with() when zero attributes' do
        expect(serializer.dump(resource_body)).to_not match(/\with\(/)
      end

      it 'returns a resource_body containing arguments with commas' do
        r_b = relationship_exp.eContents.first.eContents.first
        arguments = r_b.bodies.first.operations
        arguments.each do |p|
          expect(serializer.dump(p)).to match(/,$/)
        end
        expect(serializer.dump(resource_body)).to_not match(/\with\(/)
      end
    end

    it 'relationship_exp' do
      expect(serializer.dump(relationship_exp)).to eq(rel_data)
    end

    it 'should contain correct variables' do
      expect(serializer.var_store).to eq(store)
    end
  end

  describe 'variable store' do
    it 'should add a variable' do
      expect(serializer.var_store).to eq({})
    end

    it 'values should not contain a $' do
      expect(serializer.add_var_to_store('class_a::master_type', 'value1')).to eq('value1')
      serializer.var_store.each do |key, value|
        expect(value).to_not match(/^\$'.*/)
      end
    end
    describe 'store' do
      before(:each) do
        # prime the var store
        serializer.dump(parameters)
        serializer.dump(ast)
      end

      it 'should return correct top scope' do
        expect(serializer.top_scope_vars).to eq([["$::kernel", {:value=>"$::kernel", :type=>:top_scope}]])
      end

      it 'should return correct data' do
        expect(serializer.lookup_var('$merged_ssdt_install_options')).to_not match(/it/)
      end

      it 'values should not contain a $' do
        expect(serializer.add_var_to_store('$master_type', 'value1')).to eq('value1')
        serializer.var_store.each do |key, value|
          expect(value).to_not match(/^\$'.*/)
        end
      end
      it 'should add a variable and prepend a $' do
        expect(serializer.add_var_to_store('class_a::master_type', 'value1')).to eq('value1')
        expect(serializer.lookup_var('$class_a::master_type')).to eq('value1')
        expect(serializer.lookup_var('$master_type')).to eq('value1')
      end

      it 'should add two variables' do
        expect(serializer.add_var_to_store('$class_a::master_type', 'value1')).to eq('value1')
        expect(serializer.lookup_var('$class_a::master_type')).to eq('value1')
        expect(serializer.lookup_var('$master_type')).to eq('value1')

      end

      it 'should not add a variable when it already exists' do
        serializer.add_var_to_store('$class_a::master_type', 'value1')
      end
    end

    it 'should add a variable and prepend a $' do
      expect(serializer.add_var_to_store('class_a::master_type', 'value1')).to eq('value1')
      expect(serializer.lookup_var('$class_a::master_type')).to eq('value1')
      expect(serializer.lookup_var('$master_type')).to eq('value1')
    end

    it 'should add two variables' do
      expect(serializer.add_var_to_store('$class_a::master_type', 'value1')).to eq('value1')
      expect(serializer.lookup_var('$class_a::master_type')).to eq('value1')
      expect(serializer.lookup_var('$master_type')).to eq('value1')

    end

    it 'should not add a variable when it already exists' do
      serializer.add_var_to_store('$class_a::master_type', 'value1')
    end
  end
end
