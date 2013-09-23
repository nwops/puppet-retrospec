puppet-retrospec
================

Generates puppet rspec test code based on the classes and defines inside the manifests directory.  Aims to reduce some of the boilerplate coding with default test patterns.


Build Status
============
[![Build Status](https://travis-ci.org/logicminds/puppet-retrospec.png)](https://travis-ci.org/logicminds/puppet-retrospec)

How to use
=============
At this time there is no binary wrapper around this library.

The most useful case is to add it to your rakefile.
If your using the [puppetlabs_module_spec_helper](http://github.com/branan/module-spec-helper) you should see a similar
rake task soon in the next update.

```
require 'puppet-retrospec'

desc "Scans the module directory and automatically creates basic spec tests"
task :retrospec do
  Puppet::Retrospec.run
end

```

Support
============
Currently this library only supports ruby >= 1.9.3.  There is currently a bug with ruby version 1.8.7.
