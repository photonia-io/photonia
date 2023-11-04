# frozen_string_literal: true

namespace :photos do
  task :add_intelligent_derivatives, [:photo_slug] do |_task, args|
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          if args[:photo_slug]
            execute :rake, "photos:add_intelligent_derivatives[#{args[:photo_slug]}]"
          else
            execute :rake, 'photos:add_intelligent_derivatives'
          end
        end
      end
    end
  end

  task :reset_exif do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'photos:reset_exif'
        end
      end
    end
  end

  task :populate_exif_fields do
    on roles(:app) do
      within current_path.to_s do
        with rails_env: fetch(:stage).to_s do
          execute :rake, 'photos:populate_exif_fields'
        end
      end
    end
  end
end
