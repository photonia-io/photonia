# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 6.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6.0.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11', '>= 2.11.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

gem 'acts-as-taggable-on', '~> 12.0'
gem 'aws-sdk-rekognition'
gem 'aws-sdk-s3', '~> 1.14'
gem 'devise'
gem 'devise-jwt'
gem 'exif'
gem 'friendly_id', '~> 5.5.0'
gem 'googleauth', '~> 1.11'
gem 'graphql'
gem 'graphql-pagination'
gem 'groupdate'
gem 'image_processing', '~> 1.8'
gem 'impressionist', '~> 2.0'
gem 'kramdown'
gem 'pagy', '~> 9'
gem 'paper_trail'
gem 'pg_search'
gem 'pundit'
gem 'rails-settings-cached', '~> 2.9'
gem 'redis'
gem 'sentry-rails', '~> 5.8'
gem 'sentry-ruby', '~> 5.8'
gem 'shrine', '~> 3.0'
gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 5.0'
gem 'sitemap_generator'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'vite_rails', '~> 3.0', '>= 3.0.14'
gem 'warden-jwt_auth', git: 'https://github.com/photonia-io/warden-jwt_auth', branch: 'add-request-body-matcher'

group :development, :test do
  gem 'bcrypt_pbkdf'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'ed25519'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry'
  gem 'rspec_junit_formatter' # for CircleCI
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-graphql'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
end

group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'graphiql-rails'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 4.1'
  gem 'spring-watcher-listen', '~> 2.1'
  gem 'web-console', '>= 4.2.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.38.0'
  gem 'pundit-matchers', '~> 4.0'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 6.1'
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
  gem 'timecop'
end
