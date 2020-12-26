# frozen_string_literal: true

# Usage: rails users:create[user@email.com,password]

namespace :users do
  desc 'Create a user'
  task :create, [:email, :password] => [:environment] do |_t, args|
    User.create(email: args[:email], password: args[:password], password_confirmation: args[:password])
  end
end
