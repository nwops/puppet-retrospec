--- !ruby/object:Gem::Specification
name: puppet
version: !ruby/object:Gem::Version
  version: 4.5.2
platform: ruby
authors:
- Puppet Labs
autorequire: 
bindir: bin
cert_chain: []
date: 2016-06-14 00:00:00.000000000 Z
dependencies:
- !ruby/object:Gem::Dependency
  name: facter
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - <
      - !ruby/object:Gem::Version
        version: '4'
    - - '>'
      - !ruby/object:Gem::Version
        version: '2.0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - <
      - !ruby/object:Gem::Version
        version: '4'
    - - '>'
      - !ruby/object:Gem::Version
        version: '2.0'
- !ruby/object:Gem::Dependency
  name: hiera
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - <
      - !ruby/object:Gem::Version
        version: '4'
    - - '>='
      - !ruby/object:Gem::Version
        version: '2.0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - <
      - !ruby/object:Gem::Version
        version: '4'
    - - '>='
      - !ruby/object:Gem::Version
        version: '2.0'
- !ruby/object:Gem::Dependency
  name: json_pure
  requirement: !ruby/object:Gem::Requirement
    requirements:
    - - '>='
      - !ruby/object:Gem::Version
        version: '0'
  type: :runtime
  prerelease: false
  version_requirements: !ruby/object:Gem::Requirement
    requirements:
    - - '>='
      - !ruby/object:Gem::Version
        version: '0'
description: Puppet, an automated configuration management tool
email: info@puppetlabs.com
executables:
- puppet
extensions: []
extra_rdoc_files: []
files:
- bin/puppet
homepage: https://github.com/puppetlabs/puppet
licenses: []
metadata: {}
post_install_message: 
rdoc_options:
- --title
- Puppet - Configuration Management
- --main
- README.md
- --line-numbers
require_paths:
- lib
required_ruby_version: !ruby/object:Gem::Requirement
  requirements:
  - - '>='
    - !ruby/object:Gem::Version
      version: 1.9.3
required_rubygems_version: !ruby/object:Gem::Requirement
  requirements:
  - - '>'
    - !ruby/object:Gem::Version
      version: 1.3.1
requirements: []
rubyforge_project: puppet
rubygems_version: 2.0.14
signing_key: 
specification_version: 3
summary: Puppet, an automated configuration management tool
test_files: []

