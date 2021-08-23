# frozen_string_literal: true

namespace :photos do
  task :add_intelligent_derivatives do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'photos:add_intelligent_derivatives'
        end
      end
    end
  end

  task :new_derivatives_step_1 do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'photos:new_derivatives_step_1'
        end
      end
    end
  end
end
