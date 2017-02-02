source 'http://rubygems.org'

gem 'trollop'
gem 'retrospec', '~> 0.5'
gem 'awesome_print'
gem 'facets'

group :development do
  gem 'rdoc', '~> 3.12'
  gem 'pry'
end

group :test do
  gem 'rubocop', platforms: :ruby_20
  gem 'rspec', '~> 3.2'
  gem 'puppet', '4.5.2', :path => 'vendor/gems/puppet-4.5.2'
  gem 'json_pure', '= 2.0.1' # force this gem as 2.0.2 requires ruby > 2.0.0
  gem 'rake'
  gem 'bundler', '~> 1.0'
  gem 'yard', '~> 0.7'
  gem 'fakefs', :require => 'fakefs/safe'
end
