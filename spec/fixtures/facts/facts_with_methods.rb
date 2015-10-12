# this is just an example fact that uses method logic outside the Facter.add block
def default_kernel
  if Facter.value(:kernel) == 'Windows'
    'Windows'
  else
    'Linux'
  end
end

Facter.add(:method_fact) do
  confine :kernel => 'Linux'
  confine :osfamily => 'RedHat'
  setcode do
    is_virtual = Facter.fact(:is_virtual).value
    default_kernel
    Facter::Core::Execution.execute('which lsb')
  end
end

