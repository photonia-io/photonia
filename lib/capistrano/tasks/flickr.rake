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
end
