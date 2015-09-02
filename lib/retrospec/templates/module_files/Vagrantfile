def vm(opt)
  module_name = opt.fetch(:module).to_s || raise(ArgumentError, 'Must provide puppet module name')
  hostname = opt.fetch(:hostname, module_name).to_s
  memory = opt.fetch(:memory, 512)
  cpu = opt.fetch(:cpu, 1)
  box = opt.fetch(:box).to_s || raise(ArgumentError, 'Must provide box type.')
  url = opt.fetch(:url, '').to_s
  os_type = opt[:os_type] || opt[:type] || :linux
  gui = opt.fetch(:gui, false)
  ports = Array(opt.fetch(:port, []))
  iso = opt.fetch(:iso, nil)
  proj_root = File.expand_path(File.join(File.dirname(__FILE__)))
  fixture_modules = File.join(proj_root, 'spec', 'fixtures', 'modules')

  Vagrant.configure('2') do |conf|

    # forward all the ports
    ports.each do |p|
      conf.vm.network(:forwarded_port, guest: p, host: p, auto_correct: true)
    end

    if os_type == :windows
      conf.ssh.username = 'vagrant'
      conf.winrm.username = 'vagrant'
      conf.winrm.password = 'vagrant'
    end

    conf.vm.define hostname.to_sym do |mod|
      mod.vm.box = box
      mod.vm.box_url = url

      if os_type == :windows
        mod.vm.guest = :windows
        mod.vm.communicator = 'winrm'
        mod.vm.synced_folder './' , "/ProgramData/PuppetLabs/puppet/etc/modules/#{module_name}"
        mod.vm.synced_folder 'spec/fixtures/modules' , '/temp/modules'
      else
        mod.vm.synced_folder './', "/etc/puppet/modules/#{module_name}"
        mod.vm.synced_folder 'spec/fixtures/modules', '/tmp/puppet/modules'
      end

      mod.vm.hostname = hostname

      mod.vm.provider :vmware_fusion do |f|
        f.gui = gui
        f.vmx['displayName'] = hostname
        f.vmx['memsize'] = memory
        f.vmx['numvcpus'] = cpu
        if iso
          f.vmx['ide1:0.devicetype'] = "cdrom-image"
          f.vmx['ide1:0.filename'] = iso
        end
      end

      mod.vm.provider :vmware_workstation do |f|
        f.gui = gui
        f.vmx['displayName'] = hostname
        f.vmx['memsize'] = memory
        f.vmx['numvcpus'] = cpu
        if iso
          f.vmx['ide1:0.devicetype'] = "cdrom-image"
          f.vmx['ide1:0.filename'] = iso
        end
      end

      mod.vm.provider :virtualbox do |v|
        v.gui = gui
        v.name = hostname
        v.memory = memory
        v.cpus = cpu
      end

      if os_type == :windows
        manifest = ENV['VAGRANT_MANIFEST'] || 'init.pp'
        #mod.vm.provision :shell, :inline => "@powershell -NoProfile -ExecutionPolicy Bypass -Command \"iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))\" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
        #mod.vm.provision :shell, :inline => "choco install puppet"
        mod.vm.provision :shell, :inline => "puppet apply --modulepath 'C:/ProgramData/PuppetLabs/puppet/etc/modules;C:/temp/modules' --verbose C:/ProgramData/PuppetLabs/puppet/etc/modules/#{module_name}/tests/#{manifest}"
      else
        mod.vm.provision :puppet do |p|
          p.manifests_path = 'tests'
         # p.hiera_config_path = File.join(fixture_modules, 'hieradata', 'hiera.yaml')
          p.manifest_file = ENV['VAGRANT_MANIFEST'] || 'init.pp'
          #p.module_path = fixture_modules
          # because of how symlinks are handled via the spec_helper we are forced to mount the modules is different locations
          # otherwise we could just use the above option
          p.options = '--modulepath="/etc/puppet/modules:/tmp/puppet/modules"'
        end
      end
    end
  end
end
module_name = File.basename(File.expand_path(File.join(File.dirname(__FILE__))))
vm :hostname => 'win2012r2', :module => module_name, :box => 'opentable/win-2012r2-standard-amd64-nocm', :url => 'opentable/win-2012r2-standard-amd64-nocm', :os_type => :windows, :cpu => 1, :memory => 4096, :gui => true
vm :hostname => 'win2008r2', :module => module_name, :box => 'opentable/win-2008r2-standard-amd64-nocm', :url => 'opentable/win-2008r2-standard-amd64-nocm', :os_type => :windows, :cpu => 1, :memory => 4096, :gui => true
vm :hostname => 'centos6', :module => module_name, :box => 'puppetlabs/centos-6.6-64-puppet', :url => 'puppetlabs/centos-6.6-64-puppet', :cpu => 1, :memory => 2048, :gui => false
