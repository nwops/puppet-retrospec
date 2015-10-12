# this is just an example fact that uses confines and returns a default value
Facter.add(:node_role) do
  confine :kernel => 'Windows'
  confine :is_virtual => true
  setcode do
    'default_role'
  end
end