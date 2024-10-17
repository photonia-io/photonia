# frozen_string_literal: true

namespace :flickr do
  task :import_privacy do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'flickr:import_privacy'
        end
      end
    end
  end

  task :import_tags do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'flickr:import_tags'
        end
      end
    end
  end

  task :import_albums do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'flickr:import_albums'
        end
      end
    end
  end

  task :import_comments do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'flickr:import_comments'
        end
      end
    end
  end

  task :fetch_user_data do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'flickr:fetch_user_data'
        end
      end
    end
  end
end
