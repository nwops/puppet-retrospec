vendor = File.join(File.dirname(File.dirname(__FILE__)),'vendor')
$:.unshift(File.expand_path(File.join([vendor, "gems", "puppet-3.7.3", "lib"])))
require 'retrospec/plugins/v1/plugin/puppet'
require 'awesome_print'  # required for printing templates

