# frozen_string_literal: true

# If you're using zsh, you need to escape the square brackets

namespace :users do
  # Usage: rails users:create[user@email.com,password]

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

  # Usage: rails users:make_admin[user@email.com]

  desc 'Makes a user an admin'
  task :make_admin, [:email] => [:environment] do |_t, args|
    user = User.find_by(email: args[:email])
    user.update(admin: true)
  end
end
