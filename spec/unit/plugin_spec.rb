require 'spec_helper'
require 'retrospec'

describe "puppet" do
  let(:plugin) do
    Retrospec::Plugins::V1::Puppet.new('/tmp/testplugin_dir', {:name => 'testplugin', :config1 => 'test', :create => true})
  end

  it 'can show the version' do
    expect(Retrospec::Puppet::VERSION).to eq('0.9.1')
  end

  it 'can get cli options' do
    expect(Retrospec::Plugins::V1::Puppet.cli_options({:module_path => '/tmp/testplugin_dir'})[:enable_future_parser]).to be false
  end


  it 'can get cli options' do
    expect(Retrospec::Plugins::V1::Puppet.cli_options({:module_path => '/tmp/testplugin_dir', 'plugins::puppet::enable_future_parser' => true})[:enable_future_parser]).to be true
  end
end
