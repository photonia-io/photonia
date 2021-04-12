# frozen_string_literal: true

# Usage: rails users:create[user@email.com,password]

namespace :users do
  desc 'Create a user'
  task :create, %i[email password] => [:environment] do |_t, args|
    User.create(email: args[:email], password: args[:password], password_confirmation: args[:password])
  end

  # Usage: rails users:assign_photos[user@email.com]

  desc 'Assigns all photos to a user'
  task :assign_photos, [:email] => [:environment] do |_t, args|
    user = User.find_by(email: args[:email])
    Photo.unscoped.update_all(user_id: user.id)
  end
end
