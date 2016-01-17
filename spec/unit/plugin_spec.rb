require 'spec_helper'
require 'retrospec'

describe 'puppet' do
  let(:plugin) do
    Retrospec::Plugins::V1::Puppet.new('/tmp/testplugin_dir', :name => 'testplugin', :config1 => 'test')
  end

  let(:global_opts) do
    { :module_path => '/tmp/testplugin_dir' }
  end

  before :each do
    FileUtils.rm_rf('/tmp/testplugin_dir')
  end

  it 'can show the version' do
    expect(Retrospec::Puppet::VERSION).to be_instance_of(String)
  end

end
