# frozen_string_literal: true

namespace :flickr do
  task :privacy do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'flickr:privacy'
        end
      end
    end
  end
end
