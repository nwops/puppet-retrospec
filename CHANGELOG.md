# Retrospec Puppet Release Notes

## Unreleased
 * Require the base generator for module data
 * Fixes #85 - native functions do not contain module name
 * Fixes #92 - that requires throws errors
 * Fixes #93 - native functions spec tests contain full namespaced name
 * Fixes #87 - evaluation fails when parameters have logic
## 1.6.0
 * Fixes #77 - class requirements is not coded correctly
 * Fixes #75 - pdk cannot include retrospec due to character limit
 * Fixes #80 - update vendored puppet gem to v4.10.x from 4.5.x
 * Fixes #72 - create spec files that conform to rubocop [@b4ldr]
 * Removes ci tags that pinned to ruby2.2 when testing
 * Fixes #81 - pass correct git ref [@witjoh]
 * Fixes #74 - parameters with a default value of arrays cause error
 * Adds more documentation to methods
 * Fixes timestamp bug when creating the gem in rubygems.org
## 1.5.0
 * Adds ability to generate bolt tasks for puppet modules
## 1.4.1
 * Adds real module data to common.yaml
## 1.4.0
 * Fixes gh-67 - adds abiltity to auto generate data in a module
 * Forces retrospec version 0.6.2 or greater
## 1.3.2
 * Fixes gh-70 - Finding puppetfiles in nested folders
## 1.3.1
 * adds ability to sync files
## 1.3.0
 * fixes gh-68 - add ability to overwrite generated files
 * updates README
 * removes old rakefile code
 * bumps retrospec gem to 0.5
## 1.2.1
 * fix conditional logic preventing hooks from running
## 1.2.0
 * fixes gh-53 - adds windows support
## 1.1.0
 * fixes gh-62 - add support for creating native puppet fuctions
## 1.0.0
 This is a major release which vendors the latest puppet version.  The core parser
 was rewritten to use the new puppet parser and opens up a bunch of new possibilities
 for generating more test coverage.
 This release is a breaking release which requires your puppet code to adhere
 to the new parser rules.  If you are not able update your puppet code you should use the pre 1.x releases of retrospec puppet.

 * Fixes gh-56 - variable_value: rendering values with escapes creates invalid tests
 * Fixes gh-15 - nested conditionals are not discovered
 * Fixes gh-54 - Vendored puppet 3.7 doesn't work on newer rubies

## 0.12.2
 * fixes issue with ruby193 and openstruct
 * fix unit tests from failing on missing hook file
 * group gems more intelligently for ci testing
 * add better exception handling
 * adds a default properties for the provider context
## 0.12.0
 * fix an annoying issue when creating new modules and current directory
 * gh-38 - added ability to create new types and type unit tests
 * gh-39 - add functionality to create new providers
 * gh-40 - add ability to generate functions
 * gh-43 - add ability to create kwalify schema files
 * gh-42 - continue with creating files when retrospec parser fails on invalid code
## 0.11.0
 * gh-31 - add ability to generate new fact and spec tests
 * add awesome_print gem
 * gh-37 - move new module functionality to its own generator class
## 0.10.0
 * refactor cli options to use retrospec 0.4.0 specifications
 * gh-32 - add ability to create new module
 * fix pinning of module to use 0.x.0 instead of 0.x
 * pin to version 0.4.x
## 0.9.0
 * convert to retrospec plugin
 This is a big change in how you run puppet-retrospec please see the readme for changes.

## 0.8.1
 * gh-30 - add support for host resource types
## 0.8.0
 * enable broader support for future parser
 * remove hiera and facter dependencies
 * added support for running pre and post hooks gh-27
 * added support for running a hook to clone external templates
 * externalized the templates into their own repo gh-26
 * handle symlinks in the templates directory correctly gh-28

## 0.7.3
 * added hiera data helper to fill in all the auto bindable class params in shared_contexts
 * updated hiera data gem to newer fork that works with puppet 3.5+
 * minor fixes in templates
 * added vagrantfile for easier manual integration testing

## 0.7.2
 * vendor the puppet gem

## 0.7.0
 * gh-18 puppet 4 code syntax does not work
 * gh-10 safe file creation should use colors

## 0.6.1
 * gh-12 - allow new templates to be easily added without changing code
 * gh-8 - tests are not created when manifest is invalid
 * updated README based on apache example
 * updated templates to fix minor errors

## 0.6.0
Initial release that was deemed worthy.
