# frozen_string_literal: true

namespace :albums do
  task :reset do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'albums:reset'
        end
      end
    end
  end

  task :maintenance do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'albums:maintenance'
        end
      end
    end
  end
end
