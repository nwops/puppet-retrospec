# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "puppet"
  s.version = "4.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Puppet Labs"]
  s.date = "2016-01-21"
  s.description = "Puppet, an automated configuration management tool"
  s.email = "info@puppetlabs.com"
  s.executables = ["puppet"]
  s.files = ["bin/puppet"]
  s.homepage = "https://github.com/puppetlabs/puppet"
  s.rdoc_options = ["--title", "Puppet - Configuration Management", "--main", "README.md", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "puppet"
  s.rubygems_version = "2.0.14"
  s.summary = "Puppet, an automated configuration management tool"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<facter>, ["< 4", "> 2.0"])
      s.add_runtime_dependency(%q<hiera>, ["< 4", ">= 2.0"])
      s.add_runtime_dependency(%q<json_pure>, [">= 0"])
    else
      s.add_dependency(%q<facter>, ["< 4", "> 2.0"])
      s.add_dependency(%q<hiera>, ["< 4", ">= 2.0"])
      s.add_dependency(%q<json_pure>, [">= 0"])
    end
  else
    s.add_dependency(%q<facter>, ["< 4", "> 2.0"])
    s.add_dependency(%q<hiera>, ["< 4", ">= 2.0"])
    s.add_dependency(%q<json_pure>, [">= 0"])
  end
end

