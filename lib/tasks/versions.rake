# frozen_string_literal: true

namespace :versions do
  desc 'Create initial versions for photos, albums, and comments'
  task create_initial: :environment do
    models = [Photo, Album, Comment]

    models.each do |model|
      model.unscoped.find_each do |record|
        if record.versions.empty?
          record.paper_trail.save_with_version
          puts "Created initial version for #{model.name} with ID #{record.id}"
        else
          puts "Initial version already exists for #{model.name} with ID #{record.id}"
        end
      end
    end

    puts 'Initial versions creation completed.'
  end
end
