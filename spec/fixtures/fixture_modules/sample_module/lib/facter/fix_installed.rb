Facter.add(:fix_installed) do
  confine :kernel => 'windows'
  setcode do
    puts client_executable
    File.exists?(client_executable)
  end
end

def client_executable
  "C:\\Program Files (x86)\\some.exe"
end
