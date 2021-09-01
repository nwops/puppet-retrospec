source 'http://rubygems.org'

gem 'awesome_print'
gem 'facets'
gem 'retrospec', git: 'https://github.com/nwops/retrospec.git'
gem 'optimist', '~> 3.0.0'

group :development do
  gem 'pry'
  gem 'rdoc', '~> 6.3'
  gem 'overcommit'
end

group :test do
  gem 'rb-readline'
  gem 'bundler', '~> 2.0'
  gem 'fakefs', :require => 'fakefs/safe'
  gem 'json_pure', '= 2.0.1' # force this gem as 2.0.2 requires ruby > 2.0.0
  gem 'puppet', '4.10.8', :path => 'vendor/pup410'
  gem 'rake'
  gem 'facter'
  gem 'rspec', '~> 3.2'
  gem 'rubocop'
  gem 'yard', '~> 0.7'
  gem 'puppet-retrospec', :path => './'
end
