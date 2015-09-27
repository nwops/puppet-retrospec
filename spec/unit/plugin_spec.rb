require 'spec_helper'
require 'retrospec'

describe "puppet" do
  let(:plugin) do
    Retrospec::Plugins::V1::Puppet.new('/tmp/testplugin_dir', {:name => 'testplugin', :config1 => 'test'})
  end

  it 'can show the version' do
    expect(Retrospec::Puppet::VERSION).to eq('0.9.0')
  end

  it 'can get cli options' do
    expect(Retrospec::Plugins::V1::Puppet.cli_options({})[:enable_future_parser]).to be false
  end


  it 'can get cli options' do
    expect(Retrospec::Plugins::V1::Puppet.cli_options({'plugins::puppet::enable_future_parser' => true})[:enable_future_parser]).to be true
  end
end
