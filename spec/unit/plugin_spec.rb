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

  # disabling for now until we can stub gets
  xit 'can run cli and create new module' do
    expect(Retrospec::Plugins::V1::Puppet.run_cli(global_opts, {}, {}, ['new_module'])).to eq(nil)
  end

  xit 'can run cli' do
    Retrospec::Plugins::V1::Puppet.run_cli(global_opts, {}, {}, ['new_module'])
    expect(Retrospec::Plugins::V1::Puppet.run_cli(global_opts, {}, {}, [])).to eq(nil)
  end
end
