vendor = File.join(File.dirname(File.dirname(__FILE__)), 'vendor')
# pdk cannot load retrospec-puppet on windows due to 256 char limit
# so we reduced the folder name to pup410
$LOAD_PATH.unshift(File.expand_path(File.join([vendor, 'pup410', 'lib'])))
require 'retrospec/plugins/v1/plugin/puppet'
require 'awesome_print' # required for printing templates
