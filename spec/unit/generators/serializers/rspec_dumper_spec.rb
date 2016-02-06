require 'spec_helper'
require 'retrospec/plugins/v1/plugin/generators/serializers/rspec_dumper'

describe 'rspec_serializer' do

  before(:each) do
    # prime the var store
    serializer.dump(parameters)
    serializer.dump(ast)

  end
  let(:sample_file) do
    '/Users/cosman/singlestone/modules/sql2014/manifests/init.pp'
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
    store = {"$sql2014::features_location"=>"()", "$sql2014::source"=>"()",
      "$sql2014::backup_root_dir"=>"'c:\\backup'", "$sql2014::install_type"=>"'default'",
      "$sql2014::install_options"=>["{}"], "$sql2014::install_accounts"=>["{}"],
      "$sql2014::install_account_passwords"=>["{}"],
      "$sql2014::instance_name"=>"'MSSQLSERVER'", "$sql2014::ssdt_install_options"=>["{}"],
      "$install_type"=>"$install_type", "$install_options"=>"$install_options",
      "$merged_options"=>"$merged_options", "$install_flags"=>"$install_flags",
      "$merged_ssdt_install_options"=>"$merged_ssdt_install_options",
      "$ssdt_install_options"=>"$ssdt_install_options",
      "$install_accounts"=>"$install_accounts",
      "$install_account_passwords"=>"$install_account_passwords",
      "$instance_name"=>"$instance_name", "$source"=>"$source",
      "$features_location"=>"$features_location", "$backup_root_dir"=>"$backup_root_dir"}
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
    ":features_location => \n:source => \n#:backup_root_dir => 'c:\\backup'\n#:install_type => 'default'\n#:install_options => {}\n#:install_accounts => {}\n#:install_account_passwords => {}\n#:instance_name => 'MSSQLSERVER'\n#:ssdt_install_options => {}\n"
  end

  let(:rel_data) do
    "it do\n  is_expected.to contain_class('sql2014::install')\n    .with(\n      \"sql_install_flags\" =>\n      \"instance_name\" =>\n      \"installer_source\" =>\n      \"features_location\" =>\n      \"ssdt_options\" =>\n      \n    )\nend\n\nit do\n  is_expected.to contain_sql2014__backup($instance_name)\n    .with(\n      \"backup_root_dir\" =>\n      \n    )\nend\n\nit do\n  is_expected.to contain_class('sql2014::login')\nend\n"
  end

  it 'should generate the content for a parameters' do
    expect(serializer.dump(parameters)).to eq(parameter_data)
  end

  it 'should comment out default parameters' do
    expect(serializer.dump(parameters.last)).to match(/\#{1}/)
  end

  it 'should force user to fill out parameter' do
    expect(serializer.dump(parameters.first)).to match(/[^#]{1}/)
  end

  # it 'should generate the content for an ast' do
  #   expect(serializer.dump(ast)).to eq('')
  # end
  # it 'should generate the content for a host class' do
  #   expect(serializer.dump(hostclass)).to eq('')
  # end
  #
  # it 'should generate the content for a host class' do
  #   expect(serializer.dump(hostclass_body)).to eq('')
  # end
  #
  it 'should generate content for case option' do
    # test = serializer.dump(case_exp.test)
    # ls, exp = case_exp.options.first.eContents
    # case_exp.options.first.eContents
    # options = case_exp.options
    expect(serializer.dump(case_exp.options.first)).to match(/context\ 'custom'\ do\n/)
  end

  # it 'should generate the content for a case expr' do
  #   expect(serializer.dump(case_exp)).to eq('')
  # end
  #
  it 'returns a resource_body containing with when contain attributes' do
    r_b = relationship_exp.eContents.first.eContents.first
    expect(serializer.dump(r_b)).to match(/\with\(/)
  end

  it 'returns a resource_body not containing with when zero attributes' do
    expect(serializer.dump(resource_body)).to_not match(/\with\(/)
  end

  it 'should generate the content for a relationship_exp' do
    expect(serializer.dump(relationship_exp)).to eq(rel_data)
  end

  it 'should contain correct variables' do
    expect(serializer.var_store).to eq({})
  end

end
