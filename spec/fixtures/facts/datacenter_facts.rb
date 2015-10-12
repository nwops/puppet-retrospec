# this is an example of a fact file with multiple facts
Facter.add(:fact1) do
  confine :kernel => 'Linux'
  setcode do
    'value1'
  end
end
Facter.add(:fact2) do
  confine :kernel => 'Windows'
  setcode do
    'value2'
    Facter::Core::Execution.execute('which lsb')

  end
end