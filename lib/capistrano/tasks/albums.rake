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

  task :copy_flickr_views_to_impressions_count do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'albums:copy_flickr_views_to_impressions_count'
        end
      end
    end
  end
end
