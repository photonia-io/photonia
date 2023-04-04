# frozen_string_literal: true

namespace :labels do
  task :reset do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'labels:reset'
        end
      end
    end
  end

  task :add_labels_from_rekognition_response do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'labels:add_labels_from_rekognition_response'
        end
      end
    end
  end
end
