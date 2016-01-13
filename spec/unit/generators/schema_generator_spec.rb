require 'spec_helper'

describe 'schema_generator' do

  before(:each) do
    FileUtils.rm(schema_file) if File.exists?(schema_file)
  end

  let(:generator_opts) do
    {:name => 'test', :puppet_context => puppet_context}
  end

  let(:module_path) do
    sample_module_path
  end

  let(:schema_file) do
    path = File.join(module_path, 'tomcat_schema.yaml')
  end

  let(:puppet_context) do
    path = File.join(fixture_modules_path, 'tomcat')
    opts = { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
      :enable_user_templates => false, :template_dir => '/tmp/.retrospec_templates' }
    mod = Retrospec::Plugins::V1::Puppet.new(opts[:module_path], opts)
    mod.post_init
    mod.context
  end

  let(:generator) do
    Retrospec::Puppet::Generators::SchemaGenerator.new(module_path, generator_opts)
  end

  let(:schema_map) do
    {"type"=>"map",
     "mapping"=>
       {"tomcat::catalina_home"=>{"type"=>"any", "required"=>false},
        "tomcat::user"=>{"type"=>"any", "required"=>false},
        "tomcat::group"=>{"type"=>"any", "required"=>false},
        "tomcat::install_from_source"=>{"type"=>"bool", "required"=>false},
        "tomcat::purge_connectors"=>{"type"=>"bool", "required"=>false},
        "tomcat::purge_realms"=>{"type"=>"bool", "required"=>false},
        "tomcat::manage_user"=>{"type"=>"bool", "required"=>false},
        "tomcat::manage_group"=>{"type"=>"bool", "required"=>false}
       }
    }
  end

  it 'should create files without error' do
    expect(generator.generate_schema_file).to eq(schema_file)
    expect(File.exists?(schema_file)).to eq(true)
  end

  it 'should contain proper mapping' do
    schema_file = generator.generate_schema_file
    expect(YAML.load_file(schema_file)).to eq(schema_map)
  end

  it 'should generate proper map' do
    expect(generator.create_map_content).to eq(schema_map)
  end

  it 'should produce correct file name' do
    expect(generator.schema_path).to eq(schema_file)
  end

  # describe 'required parameter' do
  #   let(:puppet_context) do
  #     path = File.join(fake_fixture_modules, 'required_parameters')
  #     opts = { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
  #              :enable_user_templates => false, :template_dir => '/tmp/.retrospec_templates' }
  #     mod = Retrospec::Plugins::V1::Puppet.new(opts[:module_path], opts)
  #     mod.post_init
  #     mod.context
  #   end
  #
  #   let(:generator) do
  #     Retrospec::Puppet::Generators::SchemaGenerator.new(module_path, generator_opts)
  #   end
  #
  #   let(:schema_map) do
  #     {"type"=>"map",
  #      "mapping"=>
  #        {"tomcat::catalina_home"=>{"type"=>"any", "required"=>false},
  #         "tomcat::user"=>{"type"=>"any", "required"=>false},
  #         "tomcat::group"=>{"type"=>"any", "required"=>false},
  #         "tomcat::install_from_source"=>{"type"=>"bool", "required"=>false},
  #         "tomcat::purge_connectors"=>{"type"=>"bool", "required"=>false},
  #         "tomcat::purge_realms"=>{"type"=>"bool", "required"=>false},
  #         "tomcat::manage_user"=>{"type"=>"bool", "required"=>false},
  #         "tomcat::manage_group"=>{"type"=>"bool", "required"=>false}
  #        }
  #     }
  #   end
  # end
  # it 'should detect when a parameter is required' do
  #   expect(generator.create_map_content).to eq(schema_map)
  # end

end
