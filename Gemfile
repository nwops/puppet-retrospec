source "http://rubygems.org"

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

gem 'trollop'
# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rspec", "~> 2.14"
  gem "yard", "~> 0.7"
  gem "rdoc", "~> 3.12"
  gem "bundler", "~> 1.0"
  gem "jeweler"
  gem 'pry'
  gem "fakefs", :require => "fakefs/safe"
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'pry-coolline'
 # gem 'pry-byebug'
end
