require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

# These two gems aren't always present, for instance
# on Travis with --without development
begin
  require 'puppet_blacksmith/rake_tasks'
  Blacksmith::RakeTask.new do |t|
    t.tag_pattern = "v%s" # Use a custom pattern with git tag. %s is replaced with the version number.
  end
rescue LoadError
end

PuppetLint.configuration.relative = true
PuppetLint.configuration.send("disable_80chars")
PuppetLint.configuration.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"
PuppetLint.configuration.fail_on_warnings = true

# Forsake support for Puppet 2.6.2 for the benefit of cleaner code.
# http://puppet-lint.com/checks/class_parameter_defaults/
PuppetLint.configuration.send('disable_class_parameter_defaults')
# http://puppet-lint.com/checks/class_inherits_from_params_class/
PuppetLint.configuration.send('disable_class_inherits_from_params_class')

exclude_paths = [
    "pkg/**/*",
    "vendor/**/*",
    "spec/**/*",
]
PuppetLint.configuration.ignore_paths = exclude_paths
PuppetSyntax.exclude_paths = exclude_paths

task :metadata do
  sh "metadata-json-lint metadata.json"
end

desc "Run syntax, lint, and spec tests."
task :test => [
         :syntax,
         :lint,
         :spec,
         :metadata,
     ]
def io_popen(command)
  IO.popen(command) do |io|
    io.each do |line|
      print line
      yield line if block_given?
    end
  end
end

desc 'Vagrant VM power up and provision'
task :vagrant_up, [:manifest, :hostname] do |t, args|
  args.with_defaults(:manifest => 'init.pp', :hostname => '')
  Rake::Task['spec_prep'].execute
  ENV['VAGRANT_MANIFEST'] = args[:manifest]
  provision = false
  io_popen("vagrant up #{args[:hostname]}") do |line|
    provision = true if line =~ /is already running./
  end
  io_popen("vagrant provision #{args[:hostname]}") if provision
end

# Cleanup vagrant environment
desc 'Vagrant VM shutdown and fixtures cleanup'
task :vagrant_destroy do
  Rake::Task['spec_prep'].execute
  `vagrant destroy -f`
  Rake::Task['spec_clean'].execute
end
