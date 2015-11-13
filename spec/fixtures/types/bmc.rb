Puppet::Type.newtype(:bmc) do
  @doc = "Manage BMC devices"

  ensurable do
    newvalue(:present) do
      provider.install
    end

    newvalue(:absent) do
      provider.remove
    end
  end

  newparam(:name, :namevar=>true) do
    desc "The name of the bmc device."
  end

  # This is just a simple verification to valid ip related sources
  def validaddr?(source)
    valid = /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/.match("#{source}")
    ! valid.nil?

  end
  #
  #  defaultto do
  #
  #    provider = resource[:provider].downcase
  #    if provider =~ /freeipmi|impitool/
  #      # check to see that openipmi driver is loaded and ipmi device exists
  #      opendriver = File.exists?('/dev/ipmi0') || File.exists?('/dev/ipmi/0') || File.exists?('/dev/ipmidev/0')
  #      if not opendriver
  #        raise ArgumentError , "The openipmi driver cannot be found, is openipmi installed and loaded correctly?"
  #      end
  #      :ipmitool
  #    elsif provider == "oem"
  #      case $manufacturer.downcase!
  #        when "hp", "hewlett packard"
  #        # check if hp's ilo driver is installed
  #        if not File.exists?('/dev/hpilo/dXccbN')
  #          raise ArgumentError , "The hp ilo driver cannot be found, is the ilo driver installed and loaded?"
  #        else
  #          return :hp
  #        end
  #        else
  #        raise ArgumentError , "The manufacturer \"#{$manufacturer}\" is currently not
  #                                           supported under the oem provider, please try freeipmi or ipmitool"
  #      end
  #
  #    end
  #  end
  #end


  newproperty(:ipsource) do
    desc "The type of ip address to use static or dhcp"
    newvalues(:static, :dhcp)
    defaultto{:dhcp}

  end

  newproperty(:ip) do
    desc "The ip address of the bmc device"
    validate do |value|
      valid = /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/.match("#{value}")
      if valid.nil?
        raise ArgumentError , "%s is not a valid ip" % value
      end
    end
  end

  newproperty(:netmask) do
    desc "The netmask address of the bmc device"
    validate do |value|
      valid = /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/.match("#{value}")
      if valid.nil?
        raise ArgumentError , "%s is not a valid netmask" % value
      end
    end
  end

  newproperty(:gateway) do
    desc "The gateway address of the bmc device"
    validate do |value|
      valid = /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/.match("#{value}")
      if valid.nil?
        raise ArgumentError , "%s is not a valid gateway" % value
      end
    end
  end

  newproperty(:vlanid) do
    defaultto {"off"}
    validate do |value|
      unless (1..4094).include?(value.to_i) or value == "off"
        raise ArgumentError , "%s is not a valid vlan id, must be 1-4094" % value
      end
    end
  end

end


