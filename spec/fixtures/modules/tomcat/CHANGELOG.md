##2015-06-09 - Supported Release 1.3.0
###Summary

This is a feature release, with a couple of bugfixes and readme changes.

####Features
- Update additional_attributes to support values with spaces
- Documentation changes
- Add a manifest for Context Containers in Tomcat configuration
- Manage User and Roles in Realms
- New manifests for context.xml configuration
- Added manifest for managing Realm elements in server.xml
- Ordering of setenv entries
- Adds parameter for enabling Tomcat service on boot
- Add ability to specify server_config location
- Allow configuration of location of server.xml

####Bugfixes
- Make sure setenv entries have export
- Test improvements
- version pinning for acceptance tests

##2014-11-11 - Supported Release 1.2.0
###Summary

This is primarily a feature release, with a couple of bugfixes for tests and metadata.

####Features
- Add `install_from_source` parameter to class `tomcat`
- Add `purge_connectors` parameter to class `tomcat` and define `tomcat::server::connector`

####Bugfixes
- Fix dependencies to remove missing dependency warnings with the PMT
- Use `curl -k` in the tests

##2014-10-28 - Supported Release 1.1.0
###Summary

This release includes documentation and test updates, strict variable support, metadata bugs, and added support for multiple connectors with the same protocol.

###Features
- Strict variable support
- Support multiple connectors with the same protocol
- Update tests to not break when tomcat releases happen
- Update README based on QA feedback

###Bugfixes
- Update stdlib requirement to 4.2.0
- Fix illegal version range in metadata.json
- Fix typo in README

##2014-09-04 - Supported Release 1.0.1
###Summary

This is a bugfix release.

###Bugfixes
- Fix typo in tomcat::instance
- Update acceptance tests for new tomcat releases

##2014-08-27 - Supported Release 1.0.0
###Summary

This release has added support for installation from packages, improved WAR management, and updates to testing and documentation.

###Features
- Updated tomcat::setenv::entry to better support installations from package
- Added the ability to purge auto-exploded WAR directories when removing WARs. Defaults to purging these directories
- Added warnings for unused variables when installing from package
- Updated acceptance tests and nodesets
- Updated README

###Deprecations
- $tomcat::setenv::entry::base_path is being deprecated in favor of $tomcat::setenv::entry::config_file

##2014-08-20 - Release 0.1.2
###Summary

This release adds compatibility information and updates the README with information on the requirement of augeas >= 1.0.0.

##2014-08-14 - Release 0.1.1
###Summary

This is a bugfix release.

###Bugfixes
- Update 'warn' to correct 'warning' function.
- Update README for use_init.
- Test updates and fixes.

##2014-08-06 - Release 0.1.0
###Summary

Initial release of the tomcat module.
