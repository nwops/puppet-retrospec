Puppet-Retrospec
================

Generates puppet rspec test code based on the classes and defines inside the manifests directory.  Aims to reduce some of the boilerplate coding with default test patterns.

Retrospec makes it dead simple to get started with puppet unit testing.  When you run retrospec will scan you puppet manifests
and actually write some very basic rspec-puppet test code.  Thus this gem will retrofit your existing puppet module
with everything needed to get going with puppet unit testing.

The project was named retrospec because there are many times when you need to retrofit your module with spec tests.

Build Status
============
[![Build Status](https://travis-ci.org/logicminds/puppet-retrospec.png)](https://travis-ci.org/logicminds/puppet-retrospec)
[![Gem Version](https://badge.fury.io/rb/puppet-retrospec.svg)](http://badge.fury.io/rb/puppet-retrospec)
Install
=============
`gem install puppet-retrospec`  


How to use
=============
Run from the command line
```
$ retrospec -h
  Options:
          --module-path, -m <s>: The path (relative or absolute) to the module directory
         --template-dir, -t <s>: Path to templates directory (only for overriding Retrospec templates)
    --enable-user-templates, -e: Use Retrospec templates from ~/.puppet_retrospec_templates
      --enable-beaker-tests, -n: Enable the creation of beaker tests
                     --help, -h: Show this message
                     
retrospec -m ~/projects/puppet_modules/apache
```

Example
======================

Below you can see that it creates files for every resource in the tomcat module in addition to other files
that you need for unit testing puppet code.

```shell
$ ls
CHANGELOG.md	CONTRIBUTING.md	LICENSE		README.md	Rakefile	checksums.json	examples	manifests	metadata.json
$ pwd
/Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat
$ retrospec
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/spec_helper.rb
!! /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/.fixtures.yml already exists and differs from template
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/Gemfile
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/shared_contexts.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/classes/
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/classes/tomcat_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/classes/params_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/config/server/
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/config/server/connector_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/config/server/engine_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/config/server/host_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/config/server/service_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/config/server/valve_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/config/server_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/instance/
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/instance/package_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/instance/source_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/instance_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/service_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/setenv/
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/setenv/entry_spec.rb
 + /Users/cosman/bodeco/puppet-retrospec/spec/fixtures/modules/tomcat/spec/defines/war_spec.rb
 
```

Looking at the file we can see that it did a lot of work for us.  Retrospec generate three tests automatically.
However the variable resolution isn't perfect so you will need to manually resolve some variables.  This doesn't produce
100% coverage but all you did was press enter to produce all this anyways.
Below is the defines/instance_spec.rb file
   
```ruby
require 'spec_helper'
require 'shared_contexts'

describe 'tomcat' do
  # by default the hiera integration uses hirea data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera


  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end
  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      #:catalina_home => "$::tomcat::params::catalina_home",
      #:user => $::tomcat::params::user,
      #:group => $::tomcat::params::group,
      #:install_from_source => true,
      #:purge_connectors => false,
      #:manage_user => true,
      #:manage_group => true,
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  it do
    should contain_file('$::tomcat::params::catalina_home').
             with({"ensure"=>"directory",
                   "owner"=>"$::tomcat::params::user",
                   "group"=>"$::tomcat::params::group"})
  end
  it do
    should contain_user('$::tomcat::params::user').
             with({"ensure"=>"present",
                   "gid"=>"$::tomcat::params::group"})
  end
  it do
    should contain_group('$::tomcat::params::group').
             with({"ensure"=>"present"})
  end
end

```

About the test suite
======================
At this time the test suite that is automatically generated is very basic.  Essentially it just creates a test for every
resource not in a code block with the exception of conditional code blocks.  While this might be all you need, the more
complex your code is the less retrospec will generate until further improvements to the generator are made.
However, one of the major stumbling blocks is just constructing everything in the spec
directory which retrospec does for you automatically.  Its now up to you to further enhance your test suite with more
tests and conditional logic using describe blocks and such.  You will notice that some variables are not resolved.
Currently this is a limitation that I hope to overcome, but until now its up to you to manually resolve those variables
prefixed with a '$'.

Example:

```ruby
should contain_file('$::tomcat::params::catalina_home').
             with({"ensure"=>"directory",
                   "owner"=>"$::tomcat::params::user",
                   "group"=>"$::tomcat::params::group"})

```

For now you will probably want to read up on the following documentation:

* [Puppet Rspec](http://rspec-puppet.com)
* [Puppet spec helper](https://github.com/puppetlabs/puppetlabs_spec_helper/blob/master/README.markdown)


How Does it do this
=======================
Basically Retrospec uses the puppet lexer and parser to scan your code in order to fill out some basic templates that will retrofit
your puppet module with unit tests.  Currently I rely on the old AST parser to generate all this.  This is why

Overriding the templates
=======================
There may be a time when you want to override the default templates used to generate the rspec related files.
To override these templates just set **one** of the following cli options.
  
```shell
      --template-dir, -t <s>:   Path to templates directory (only for overriding Retrospec templates)
    --enable-user-templates, -e:   Use Retrospec templates from ~/.puppet_retrospec_templates

```

Once one of the options is set, retrospec will copy over all the templates from the gem location to the default
or specified override templates path.
If you have already created the erb file in the templates location, then puppet-retrospec will not overwrite the file.
You can set multiple template paths if you use them for different projects so just be sure the set the correct
template option when running retrospec.

Setting the `--enable-user-templates` option will tell retrospec to use the default user template location.

The default location for the templates when using this variable is ~/.puppet_retrospec_templates

If you wish to override ~/.puppet_retrospec_templates location you can use the following option
`--template-dir`

If you set the `--template-dir` option you are not required to set the set `--enable-user-templates` option

Example:
`--template-dir=~/my_templates`

Beaker Testing
=================
Beaker is Puppetlabs acceptance testing framework that you use to test puppet code on real machines.  Beaker is fairly new
and is subject to frequent changes.  Testing patterns have not been established yet so consider beaker support in puppet-retrospec
to be experimental.

If you wish to enable the creation of beaker tests you can use the following cli option.  By default these
acceptance tests are not created.  However at a later time they will be enabled by default.

`--enable-beaker-tests`

Troubleshooting
===============
If you see the following, this error means that you need to add a fixture to the fixtures file.
At this time I have no idea what your module requires.  So just add the module that this class belongs to 
in the .fixtures file.

See [fixtures doc](https://github.com/puppetlabs/puppetlabs_spec_helper#using-fixtures) for more information

```shell
8) tomcat::instance::source
     Failure/Error: it { should compile }
     Puppet::Error:
       Could not find class staging for coreys-macbook-pro-2.local on node coreys-macbook-pro-2.local
     # ./spec/defines/instance/source_spec.rb:34:in `block (2 levels) in <top (required)>'
```

Running Tests
=============
Puppet-retrospec tests its code against real modules downloaded directly from puppet forge. 
We also do a little mocking as well but for the majority of the tests we download are 'fixtures'.

To run a clean test suite and re-download you must run with environment variable set
```
RETROSPEC_CLEAN_UP_TEST_MODULES=true bundle exec rake spec 
```

Otherwise to save time we skip the removal of test puppet modules therefore we don't re-download
```
bundle exec rake spec
```

Understanding Variable Resolution
=============
I do my best to try and resolve all the variables.  Because the code does not rely on catalog compilation we have to
build our own scope through non trival methods.  Some variables will get resolved while others will not.  As this code
progresses we might find a better way at resolving variables.  For now, some variable will require manual interpolation.

Resolution workflow.

1. load code in parser and find all parameters. Store these parameter values.
2. Find all vardef objects, resolve them if possible and store the values
3. Anything contained in a block of code is currently ignored, until later refinement.

Todo
============
- Add support to fill out used facts in the unit tests automatically
- Add describe blocks around conditions in test code that change the catalog compilation
- Auto add dependencies to fixtures file
- Show a diff of the test file when retrospec is run multiple times and the test file is already created.

Support
============
Currently this library only supports ruby >= 1.9.3.  It might work on 1.8.7 but I won't support if it fails.
