puppet-retrospec
================

Generates puppet rspec test code based on the classes and defines inside the manifests directory.  Aims to reduce some of the boilerplate coding with default test patterns.

Retrospec makes it dead simple to get started with puppet unit testing.  When you run retrospec will scan you puppet manifests
and actually write some very basic rspec-puppet test code.  Thus this gem will retrofit your existing puppet module
with everything needed to get going with puppet unit testing.


Build Status
============
[![Build Status](https://travis-ci.org/logicminds/puppet-retrospec.png)](https://travis-ci.org/logicminds/puppet-retrospec)

Install
=============
`gem install puppet-retrospec`  


How to use
=============
Run from a rake task
```
require 'puppet-retrospec'

desc "Scans the module directory and automatically creates basic spec tests"
task :retrospec do
  Retrospec.run
end

```

Run from the command line
```
$ retrospec -h
Options:
          --module-path, -m <s>:   destination directory to create spec tests in (Defaults to current directory)
         --template-dir, -t <s>:   Path to templates directory (only for overriding Retrospec templates)
    --enable-user-templates, -e:   Use Retrospec templates from /Users/cosman/.puppet_retrospec_templates
                     --help, -h:   Show this message

```

How Does it do this
=======================
Basically Retrospec uses the puppet lexer to scan your code in order to fill out some basic templates that will retrofit
your puppet module with unit tests.

Overriding the templates
=======================
There may be a time when you want to override the default templates used to generate the rspec related files.
To override these templates just set the following environment variables.  Once one of the variables is set
the first run will copy over the templates from the gem location.  If you have already created the file, then
puppet-retrospec will not overwrite the file.  You can set multiple template path if you use them for 
different projects so just be sure the set the correctly template path.

Setting the `RETROSPEC_ENABLE_LOCAL_TEMPLATES=true` Environment variable will tell retrospec to use the default user template location.

The default override location for the templates is ~/.puppet_retrospec_templates

If you wish to override the default template location you can use the following environment variable RETROSPEC_TEMPLATES_PATH.
If you set this variable you are not required set RETROSPEC_ENABLE_LOCAL_TEMPLATES.

`RETROSPEC_TEMPLATES_PATH=~/my_templates`

Todo
============
- Add support to fill out the params in unit tests automatically
- Add support to fill out used facts in the unit tests automatically
- Add describe blocks around conditions in test code that change the catalog compilation
- Auto add dependicies to fixtures file

Support
============
Currently this library only supports ruby >= 1.9.3.  There is currently a bug with ruby version 1.8.7.
