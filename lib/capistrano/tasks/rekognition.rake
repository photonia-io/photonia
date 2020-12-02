# frozen_string_literal: true

namespace :rekognition do
  task :tag_batch do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'rekognition:tag_batch'
        end
      end
    end
  end
end
