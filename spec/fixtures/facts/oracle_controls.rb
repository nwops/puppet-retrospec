require 'json'

Facter.add(:oracle_controls) do
  setcode do
    confine :kernel => 'Linux'
    confine :type => 'oracle'
    script_data
  end
end

# returns boolean true if all the checks pass
Facter.add(:oracle_security_status) do
  setcode do
    confine :kernel => 'Linux'
    confine :type => 'oracle'
    # check all items in the hash and return true/false if any of them have failed
    if script_data
      ! script_data.find { | item| item['status'] =~ /true/i }.empty?  # negate because an empty array means all passing
    end
  end
end

# return the data by running the check db script and store in a variable for later caching
# return nil if script cannot be run
def script_data
  unless @script_data
    script = '/some/script.sh'
    return nil unless File.exists?(script)
    cmd = "#{script}"
    json_data = Facter::Core::Execution.execute("/bin/su -c '#{cmd}' - oracle", :on_fail => nil)
    if json_data
      @script_data = JSON.parse(json_data)
    else
      @script_data = nil
    end
  end
  @script_data
end