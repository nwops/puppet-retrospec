Puppet-Retrospec
================

Generates puppet rspec test code based on the classes and defines inside the manifests directory.  Aims to reduce some of the boilerplate coding with default test patterns.

Retrospec makes it dead simple to get started with puppet unit testing.  When you run retrospec, retrospec will scan you puppet manifests
and actually write some very basic rspec-puppet test code.  Thus this gem will retrofit your existing puppet module
with everything needed to get going with puppet unit testing.

The project was named retrospec because there are many times when you need to retrofit your module with spec tests.

Table of Contents
=================

  * [Build Status](#build-status)
  * [Dependency](#dependency)
  * [Install](#install)
  * [How to use](#how-to-use)
  * [Example](#example)
  * [About the test suite](#about-the-test-suite)
  * [How Does it do this](#how-does-it-do-this)
  * [Overriding the templates](#overriding-the-templates)
  * [Adding New Templates](#adding-new-templates)
  * [Beaker Testing](#beaker-testing)
  * [Troubleshooting](#troubleshooting)
  * [Running Tests](#running-tests)
  * [Understanding Variable Resolution](#understanding-variable-resolution)
  * [Todo](#todo)
  * [Future Parser Support](#future-parser-support)
  * [Support](#support)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

Build Status
============
[![Build Status](https://travis-ci.org/logicminds/puppet-retrospec.png)](https://travis-ci.org/logicminds/puppet-retrospec)
[![Gem Version](https://badge.fury.io/rb/puppet-retrospec.svg)](http://badge.fury.io/rb/puppet-retrospec)

Dependency
============
Retrospec relies heavily on the puppet 3.7.x codebase.  Because of this hard dependency the puppet gem is vendored into the library so there should
not be conflicts with your existing puppet gem.  We also require facter and hiera as a result of some indirect puppet dependencies. If there are issues around
loading facter or hiera then we may need to also vendor the facter and hiera gems as well.
  
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
that you need for unit testing puppet code. Rspec-puppet best practices says to put definitions in a defines folder
and classes in a classes folder since it infers what kind of resource it is based on this convention.  Retrospec sets up
this scaffolding for you.

```shell
$ pwd
/Users/cosman/github/puppetlabs-apache
$ retrospec
 + /Users/cosman/github/puppetlabs-apache/Gemfile
  + /Users/cosman/github/puppetlabs-apache/Rakefile
  + /Users/cosman/github/puppetlabs-apache/spec/
  + /Users/cosman/github/puppetlabs-apache/spec/shared_contexts.rb
  + /Users/cosman/github/puppetlabs-apache/spec/spec_helper.rb
  + /Users/cosman/github/puppetlabs-apache/.fixtures.yml
  + /Users/cosman/github/puppetlabs-apache/.gitignore
  + /Users/cosman/github/puppetlabs-apache/.travis.yml
  + /Users/cosman/github/puppetlabs-apache/spec/classes/
  + /Users/cosman/github/puppetlabs-apache/spec/classes/default_mods_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/dev_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/apache_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/alias_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/auth_basic_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/auth_kerb_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/autoindex_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/cache_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/cgi_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/cgid_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/dav_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/dav_fs_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/dav_svn_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/deflate_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/dev_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/dir_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/disk_cache_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/fcgid_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/headers_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/info_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/itk_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/ldap_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/mime_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/mime_magic_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/mpm_event_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/negotiation_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/passenger_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/perl_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/php_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/prefork_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/proxy_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/proxy_balancer_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/proxy_html_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/proxy_http_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/python_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/reqtimeout_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/rewrite_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/setenvif_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/ssl_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/status_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/suphp_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/userdir_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/vhost_alias_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/worker_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/wsgi_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/mod/xsendfile_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/params_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/php_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/proxy_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/python_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/service_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/classes/ssl_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/defines/
  + /Users/cosman/github/puppetlabs-apache/spec/defines/balancer_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/defines/balancermember_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/defines/default_mods/
  + /Users/cosman/github/puppetlabs-apache/spec/defines/default_mods/load_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/defines/listen_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/defines/mod_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/defines/namevirtualhost_spec.rb
  + /Users/cosman/github/puppetlabs-apache/spec/defines/vhost_spec.rb
 
```

Looking at the file we can see that it did a lot of work for us.  Retrospec generate many tests automatically.
However the variable resolution isn't perfect so you will need to manually resolve some variables.  This doesn't produce
100% coverage but all you did was pressed enter to produce all this anyways.
Below is the classes/apache_spec.rb file.  Notice that while Retrospec created all these files, you still need to do more work.
Retrospec is only here to setup your module for testing, which might save you several hours each time you create a module.

   
```ruby
require 'spec_helper'
require 'shared_contexts'

describe 'apache' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
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
      #:default_mods => true,
      #:default_vhost => true,
      #:default_ssl_vhost => false,
      #:default_ssl_cert => $apache::params::default_ssl_cert,
      #:default_ssl_key => $apache::params::default_ssl_key,
      #:default_ssl_chain => undef,
      #:default_ssl_ca => undef,
      #:default_ssl_crl_path => undef,
      #:default_ssl_crl => undef,
      #:service_enable => true,
      #:purge_configs => true,
      #:purge_vdir => false,
      #:serveradmin => "root@localhost",
      #:sendfile => false,
      #:error_documents => false,
      #:httpd_dir => $apache::params::httpd_dir,
      #:confd_dir => $apache::params::confd_dir,
      #:vhost_dir => $apache::params::vhost_dir,
      #:vhost_enable_dir => $apache::params::vhost_enable_dir,
      #:mod_dir => $apache::params::mod_dir,
      #:mod_enable_dir => $apache::params::mod_enable_dir,
      #:mpm_module => $apache::params::mpm_module,
      #:conf_template => $apache::params::conf_template,
      #:servername => $apache::params::servername,
      #:user => $apache::params::user,
      #:group => $apache::params::group,
      #:keepalive => $apache::params::keepalive,
      #:keepalive_timeout => $apache::params::keepalive_timeout,
      #:logroot => $apache::params::logroot,
      #:ports_file => $apache::params::ports_file,
      #:server_tokens => "OS",
      #:server_signature => "On",
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  it do
    is_expected.to contain_package('httpd').
             with({"ensure"=>"installed",
                   "name"=>"$apache::params::apache_name",
                   "notify"=>"Class[Apache::Service]"})
  end
  it do
    is_expected.to contain_group('$apache::params::group').
             with({"ensure"=>"present",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_user('$apache::params::user').
             with({"ensure"=>"present",
                   "gid"=>"$apache::params::group",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_class('apache::service').
             with({"service_enable"=>"true"})
  end
  it do
    is_expected.to contain_exec('mkdir $apache::params::confd_dir').
             with({"creates"=>"$apache::params::confd_dir",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_file('$apache::params::confd_dir').
             with({"ensure"=>"directory",
                   "recurse"=>"true",
                   "purge"=>"$purge_confd",
                   "notify"=>"Class[Apache::Service]",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_concat('$apache::params::ports_file').
             with({"owner"=>"root",
                   "group"=>"root",
                   "mode"=>"0644",
                   "notify"=>"Class[Apache::Service]",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_concat__fragment('Apache ports header').
             with({"target"=>"$apache::params::ports_file",
                   "content"=>"template(apache/ports_header.erb)"})
  end
  it do
    is_expected.to contain_exec('mkdir $apache::params::mod_dir').
             with({"creates"=>"$apache::params::mod_dir",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_file('$apache::params::mod_dir').
             with({"ensure"=>"directory",
                   "recurse"=>"true",
                   "purge"=>"true",
                   "notify"=>"Class[Apache::Service]",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_exec('mkdir $apache::params::mod_enable_dir').
             with({"creates"=>"$apache::params::mod_enable_dir",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_file('$apache::params::mod_enable_dir').
             with({"ensure"=>"directory",
                   "recurse"=>"true",
                   "purge"=>"true",
                   "notify"=>"Class[Apache::Service]",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_exec('mkdir $apache::params::vhost_dir').
             with({"creates"=>"$apache::params::vhost_dir",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_file('$apache::params::vhost_dir').
             with({"ensure"=>"directory",
                   "recurse"=>"true",
                   "purge"=>"true",
                   "notify"=>"Class[Apache::Service]",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_exec('mkdir $vhost_load_dir').
             with({"creates"=>"$vhost_load_dir",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_file('$apache::params::vhost_enable_dir').
             with({"ensure"=>"directory",
                   "recurse"=>"true",
                   "purge"=>"true",
                   "notify"=>"Class[Apache::Service]",
                   "require"=>"Package[httpd]"})
  end
  it do
    is_expected.to contain_file('$apache::params::conf_dir/$apache::params::conf_file').
             with({"ensure"=>"file",
                   "content"=>"template($conf_template)",
                   "notify"=>"Class[Apache::Service]",
                   "require"=>"Package[httpd]"})
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

The default user location for the templates when using this variable is ~/.puppet_retrospec_templates

If you wish to override ~/.puppet_retrospec_templates location you can use the following option
`--template-dir`

If you set the `--template-dir` option you are not required to set the set `--enable-user-templates` option

Example:
`--template-dir=~/my_templates`

Adding New Templates
======================
Should you ever need to add new templates or normal files of any kind retrospec will automatically render and copy the template file
to the module path if you place a file inside the templates/module_files directory.  The cool thing about this feature
is that retrospec will recursively create the same directory structure you make inside the module_files directory inside your
module.  Files do not need to end in .erb will still be rendered as a erb template.

This follows the convention over configuration pattern so no directory name or filename is required when running retrospec.
Just put the template file in the directory where you want it (under module_files) and name it exactly how you want it to appear in the module and retrospec
will take care of the rest.  Please note that any file ending in .erb will have this extension automatically removed.

Example:

```shell
templates/
├── acceptance_spec_test.erb
├── module_files
│   ├── Gemfile
│   ├── Rakefile
│   └── spec
│       ├── acceptance
│       │   └── nodesets
│       │       ├── centos-59-x64.yml
│       │       ├── centos-64-x64-pe.yml
│       │       └── ubuntu-server-1404-x64.yml
│       ├── shared_contexts.rb
│       ├── spec_helper.rb
│       └── spec_helper_acceptance.rb
└── resource_spec_file.erb
```

Beaker Testing
=================
Beaker is Puppetlabs acceptance testing framework that you use to test puppet code on real machines.  Beaker is fairly new
and is subject to frequent changes.  Testing patterns have not been established yet so consider beaker support in puppet-retrospec
to be experimental.

If you wish to enable the creation of beaker tests you can use the following cli option.  By default these
acceptance tests are not created.  However at a later time they will be enabled by default.

`--enable-beaker-tests`

I am no expert in Beaker so if you see an issue with the templates, acceptance_spec_helper or other workflow, please issue
a PR.

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

If you see something like the following, this means your current module is using a much older version of Rspec.  Retrospec
using Rspec 3 syntax so you need to update your rspec version.  If you have tests that using older rspec syntax, take a look
at [transpec](https://github.com/yujinakayama/transpec)

```shell
   103) apache::vhost
        Failure/Error: is_expected.to contain_file('').
        NameError:
          undefined local variable or method `is_expected' for #<RSpec::Core::ExampleGroup::Nested_59:0x007ff9eaab75e8>
        # ./spec/defines/vhost_spec.rb:103:in `block (2 levels) in <top (required)>'

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

Future Parser Support
==============
Currently Retrospec uses the old/current AST parser for code parsing.  If your code contains future parser syntax
the current parser will fail to render some resource definitions but will still render the spec file template without parameters
and resource tests that are contained in your manifest.
Since Puppet 4 introduces many new things and breaks many other things  I am not sure
which side of the grass is greener at this time.  What I do know is that most people are using Puppet 3 and it may take
time to move to Puppet 4.  I would suspect Retrospec would be more valuable for those moving to Puppet 4
who don't have unit tests that currently have Puppet 3 codebases.  For those with a clean slate and start directly in
Puppet 4, Retrospec will still be able to produce the templates but some of the test cases will be missing if the old AST
parser cannot read future code syntax.  If your puppet 4 codebase is compatible with puppet 3 syntax there should not be an issue.

In order to allow future parser validation please run retrospec with the following option.

 ```shell
    retrospec --enable-future-parser

 ```

Todo
============
- Add support to fill out used facts in the unit tests automatically
- Add describe blocks around conditions in test code that change the catalog compilation
- Auto add dependencies to fixtures file
- Show a diff of the test file when retrospec is run multiple times and the test file is already created.

Support
============
Currently this library only supports ruby >= 1.9.3.  It might work on 1.8.7 but I won't support if it fails.
