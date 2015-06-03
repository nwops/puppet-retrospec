source "http://rubygems.org"

# while retrospec does not use facter or hiera,
# we vendor the puppet gem 3.7.3 which also requires facter and hiera
gem 'facter', '< 3', '> 1.6'
gem 'hiera', '~> 1.0'

gem 'trollop'
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rspec", "~> 2.14"
  gem 'puppet', '3.7.3',  :path => 'vendor/gems/puppet-3.7.3'
  gem 'facter', '< 3', '> 1.6'
  gem 'hiera', '~> 1.0'
  gem "yard", "~> 0.7"
  gem "rdoc", "~> 3.12"
  gem "bundler", "~> 1.0"
  gem "jeweler"
  gem 'pry'
  gem "fakefs", :require => "fakefs/safe"
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'pry-coolline'
end
