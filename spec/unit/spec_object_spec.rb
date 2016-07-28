require 'spec_helper'

describe 'spec_object' do
  let(:path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:opts) do
    { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
      :enable_user_templates => false, :template_dir => '/tmp/.retrospec_templates' }
  end

  let(:puppet_context) do
    path = File.join(fixture_modules_path, 'tomcat')
    opts = { :module_path => path, :enable_beaker_tests => false, :name => 'name-test123',
             :enable_user_templates => false, :template_dir => '/tmp/.retrospec_templates' }
    mod = Retrospec::Plugins::V1::Puppet.new(opts[:module_path], opts)
    mod.post_init
    mod.context
  end

  it 'should get all hiera data' do
    expect(puppet_context.class_hiera_data('tomcat')).to eq('tomcat::catalina_home' => nil,
                                                            'tomcat::group' => nil,
                                                            'tomcat::install_from_source' => nil,
                                                            'tomcat::manage_group' => nil,
                                                            'tomcat::manage_user' => nil,
                                                            'tomcat::purge_connectors' => nil,
                                                            'tomcat::purge_realms' => nil,
                                                            'tomcat::user' => nil)
  end

  it 'should get all hiera data' do
    expect(puppet_context.all_hiera_data).to eq('tomcat::catalina_home' => nil,
                                                'tomcat::group' => nil,
                                                'tomcat::install_from_source' => nil,
                                                'tomcat::manage_group' => nil,
                                                'tomcat::manage_user' => nil,
                                                'tomcat::purge_connectors' => nil,
                                                'tomcat::purge_realms' => nil,
                                                'tomcat::user' => nil)
  end
end
