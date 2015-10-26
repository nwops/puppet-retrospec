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


