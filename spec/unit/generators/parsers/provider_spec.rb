require 'spec_helper'

describe 'provider' do
  let(:provider_file) do
    File.join(fixtures_provider_path, 'bmc', 'ipmitool.rb')
  end

  let(:type_file) do
    File.join(fixtures_type_path, 'bmc.rb')
  end

  let(:models) do
    Retrospec::Puppet::Type.load_type(type_file, provider_file)
  end

  it 'can eval code' do
    expect(models.name).to eq(:ipmitool)
  end

  it 'contains class methods' do
    expect(models.class_methods).to eq([:ipmitoolcmd, :instances, :prefetch, :laninfo,
                                        :convert_vlanid, :convert_ip_source])
  end

  it 'contains a file' do
    expect(models.file).to eq(provider_file)
  end

  it 'contains instance methods' do
    expect(models.instance_methods).to eq([:ipmitoolcmd, :ensure, :ensure=, :ipsource,
                                           :ipsource=, :ip, :ip=, :netmask, :netmask=,
                                           :gateway, :gateway=, :vlanid, :vlanid=,
                                           :provider, :provider=, :flush, :install,
                                           :remove, :exists?])
  end

  it 'contains properties' do
    expect(models.properties).to eq([:ensure, :ipsource, :ip, :netmask, :gateway, :vlanid])
  end

  it 'contains parameters' do
    expect(models.parameters).to eq([:name, :provider])
  end
end
