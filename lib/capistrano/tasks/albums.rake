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

  task :set_description_html do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'albums:set_description_html'
        end
      end
    end
  end

  task :resync_serial_numbers do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'albums:resync_serial_numbers'
        end
      end
    end
  end
end
