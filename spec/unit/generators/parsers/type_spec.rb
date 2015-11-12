require 'spec_helper'

describe 'type' do
  describe 'bmc' do
    let(:file) do
      File.join(fixtures_type_path, 'bmc.rb')
    end

    let(:models) do
      Retrospec::Puppet::Type.load_type(file)
    end

    it 'can eval code' do
      models = Retrospec::Puppet::Type.load_type(file)
      expect(models.name).to eq(:bmc)
    end

    it 'has correct amount of properties' do
      expect(models.properties).to eq([:ensure, :ipsource, :ip, :netmask, :gateway, :vlanid])
    end

    it 'has correct amount of parameters' do
      expect(models.parameters).to eq([:name, :provider])
    end

    it 'has the correct number of instance methods' do
      expect(models.instance_methods).to eq([:validaddr?])
    end
  end

  describe 'bmcuser' do
    let(:file) do
      File.join(fixtures_type_path, 'bmcuser.rb')
    end

    let(:models) do
      Retrospec::Puppet::Type.load_type(file)
    end

    it 'can eval code' do
      models = Retrospec::Puppet::Type.load_type(file)
      expect(models.name).to eq(:bmcuser)
    end

    it 'has correct amount of properties' do
      expect(models.properties).to eq([:ensure, :id, :username, :userpass, :privlevel])
    end

    it 'has correct amount of parameters' do
      expect(models.parameters).to eq([:name, :force, :provider])
    end

    it 'has the correct number of instance methods' do
      expect(models.instance_methods).to eq([])
    end
  end
end
