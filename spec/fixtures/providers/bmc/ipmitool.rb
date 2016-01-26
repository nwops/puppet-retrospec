Puppet::Type.type(:bmc).provide(:ipmitool) do
  desc "Provides ipmitool support for the bmc type"

  commands :ipmitoolcmd => 'ipmitool'
  # if the open ipmi driver does not exist we can perform any of these configurations
  # check to see that openipmi driver is loaded and ipmi device exists
  confine :bmc_device_present => [:true, true]

  mk_resource_methods

  CHANNEL_LOOKUP = {
      'Dell Inc.'         => '1',
      'FUJITSU'           => '2',
      'FUJITSU SIEMENS'   => '2',
      'HP'                => '2',
      'Intel Corporation' => '3',
  }
  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  # the flush method will be the last method called after applying all the other
  # properties, by default nothing will be enabled or disabled unless the disable/enable are set to true
  # if we ever move to a point were we can write all the settings via one big config file we
  # would want to do that here.
  def flush
    if @property_flush
      if @property_flush[:disable]
        disable_channel  #TODO is this needed?
      elsif @property_flush[:enable]
        enable_channel  # TODO is this needed? what does this do ?
      end
    end
    # resets the interface
    Puppet.debug('rebooting the bmc device')
    ipmitoolcmd(['bmc', 'reset', 'cold'])
  end

  ##### These are the default ensurable methods that must be implemented
  def install
    if resource[:ipsource] == :static
      ip = resource[:ip]
      netmask = resource[:netmask]
      gateway = resource[:gateway]
    end

    ipsource = resource[:ipsource]
    if resource[:vlanid]
      vlanid = resource[:vlanid]
    end
  end

  def remove
    ipsource = "dhcp"

  end

  def exists?
    @property_hash[:ensure] == :present
  end

  # return all instances of this resource which really should only be one instance
  def self.instances
    info          = self.laninfo
    inst = new(
        :name     => info["mac address"],
        :ensure   => :present,
        :ip       => info["ip address"],
        :netmask  => info["subnet mask"],
        :gateway  => info["default gateway ip"],
        :vlanid   => info["802.1q vlan id"],
        :ipsource => info["ip address source"]
    )
    [inst]
  end

  def self.prefetch(resources)
    devices = instances
    if devices
      resources.keys.each do | name|
        if provider = devices.find{|device| device.name == name }
          resources[name].provider = provider
        end
      end
    end
  end

  #def snmp
  #  # TODO implement how to get the snmp string even when the device doesn't support snmp lookups
  #end
  #
  #def snmp=(community)
  #  ipmitoolcmd 'lan set 1 snmp', community
  #end

  # end - bmc parameters

  def self.laninfo
    landata = ipmitoolcmd([ "lan", "print", CHANNEL_LOOKUP.fetch(Facter.value(:manufacturer), '1') ])
    info = {}
    landata.lines.each do |line|
      # clean up the data from spaces
      item = line.split(':', 2)
      key = item.first.strip.downcase
      value = item.last.strip
      info[key] = value
    end
    info
    info['ip address source'] = convert_ip_source(info['ip address source'])
    info["802.1q vlan id"] = convert_vlanid(info["802.1q vlan id"])
    info
  end

  def gateway=(address)
    ipmitoolcmd([ "lan", "set", channel, "defgw", "ipaddr", address ])
  end

  def ipsource=(source)
    ipmitoolcmd([ "lan", "set", channel, "ipsrc", source.to_s ])
  end

  def ip=(address)
    ipmitoolcmd([ "lan", "set", channel, "ipaddr", address ])
  end

  def netmask=(subnet)
    ipmitoolcmd([ "lan", "set", channel, "netmask", subnet ])
  end

  def vlanid=(vid)
    ipmitoolcmd([ "lan", "set", channel, "vlan", "id", vid ])
  end

  def self.convert_vlanid(id)
    if id =~ /Disabled/i
      'off'
    else
      id
    end
  end

  def self.convert_ip_source(src)
    case src
      when /static/i
        :static
      when /dhcp/i
        :dhcp
      else
        src
    end
  end

  private

  def mac
    lanconfig["mac address"]
  end

  def dhcp?
    lanconfig["ip address source"].match(/dhcp/i) != nil
  end

  def static?
    lanconfig["ip address source"].match(/static/i) != nil
  end

  def channel_enabled?
    # TODO implement how to look up this info
    true
  end

  def channel
    CHANNEL_LOOKUP.fetch(Facter.value(:manufacturer), '1')
  end

  def enable_channel
    ipmitoolcmd([ "lan", "set", channel, "access", "on" ])
  end

  def disable_channel
    ipmitoolcmd([ "lan", "set", channel, "access", "off" ])
  end

  def lanconfig
    @lanconfig ||= self.class.laninfo
  end
end
