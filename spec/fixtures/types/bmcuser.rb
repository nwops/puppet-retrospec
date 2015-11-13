Puppet::Type.newtype(:bmcuser) do
  @doc = "Manage BMC devices"


  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end
  end

  newproperty(:id) do
    desc 'The id of the user, gathered from the bmc user list'
  end

  newparam(:name) do
    desc 'The name of the resource'
  end

  newproperty(:username, :namevar => true) do
    desc "The username to be added"

  end

  newproperty(:userpass) do
    desc "The password of the user to create"
    def change_to_s(current, desire)
      "userpass is different, changing to specified password"
    end
  end

  newparam(:force) do
    desc "The force parameter will set the password of the user with every puppet run"
    newvalues(true, false)
  end

  newproperty(:privlevel) do
    desc "The privilege level type for the user"
    defaultto :ADMIN
    newvalues(:ADMIN, :USER, :OPERATOR, :CALLBACK, :ADMINISTRATOR, :NOACCESS)
  end

end