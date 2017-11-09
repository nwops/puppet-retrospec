vendor = File.join(File.dirname(File.dirname(__FILE__)), 'vendor')
$LOAD_PATH.unshift(File.expand_path(File.join([vendor, 'pup410', 'lib'])))
require 'retrospec/plugins/v1/plugin/puppet'
require 'awesome_print' # required for printing templates
