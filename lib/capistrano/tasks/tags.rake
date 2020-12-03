# frozen_string_literal: true

namespace :tags do
  task :reset do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'tags:reset'
        end
      end
    end
  end
end
