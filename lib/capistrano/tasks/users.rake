# frozen_string_literal: true

namespace :users do
  task :create, :email, :password do |_task, args|
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, "users:create[#{args[:email]},#{args[:password]}]"
        end
      end
    end
  end

  task :assign_photos, :email do |_task, args|
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, "users:assign_photos[#{args[:email]}]"
        end
      end
    end
  end

  task :make_admin, :email do |_task, args|
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, "users:make_admin[#{args[:email]}]"
        end
      end
    end
  end
end
