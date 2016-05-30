source 'http://rubygems.org'

gem 'trollop'
gem 'retrospec', '~> 0.4'
gem 'awesome_print'
gem 'facets'
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'rdoc', '~> 3.12'
  gem 'pry'
  gem 'puppet', '3.7.3', :path => 'vendor/gems/puppet-3.7.3'
end

group :test do
  gem 'puppet', '3.7.3', :path => 'vendor/gems/puppet-3.7.3'
  gem 'rake'
  gem 'bundler', '~> 1.0'
  gem 'yard', '~> 0.7'
  gem 'fakefs', :require => 'fakefs/safe'
  gem 'rspec', '~> 3.2'
end

group :build do
  gem 'jeweler'
end
