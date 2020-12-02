# frozen_string_literal: true

namespace :tagging_sources do
  task :create do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'tagging_sources:create'
        end
      end
    end
  end
end
