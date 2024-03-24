# frozen_string_literal: true

namespace :photos do
  desc 'Deletes invalid photos'
  task destroy_invalid: :environment do
    Photo.unscoped.all.each do |photo|
      unless photo.image_url(:extralarge)
        puts "Destroying photo with id = #{photo.id}"
        photo.destroy
      end
    end
  end

  desc 'Add intelligent derivatives'
  task :add_intelligent_derivatives, [:photo_slug] => :environment do |_task, args|
    def add_job(photo)
      puts "Adding job for photo #{photo.id} / #{photo.slug}"
      AddIntelligentDerivativesJob.perform_later(photo.id)
    end

    slug = args[:photo_slug]
    if slug
      add_job(Photo.unscoped.friendly.find(slug))
    else
      Photo.unscoped.find_each do |photo|
        add_job(photo) unless photo.image_url(:medium_intelligent)
      end
    end
  end

  desc 'Reset EXIF cache and set timezone for all photos'
  task reset_exif_and_timezone: :environment do
    Photo.unscoped.update_all(exif: nil, timezone: 'Bucharest')
  end

  desc 'Fix EXIF related stuff for all photos'
  task fix_exif: :environment do
    Photo.unscoped.find_each do |photo|
      # the following will also pull the exif from the file and cache it into the database
      # if it doesn't already exist
      photo.populate_exif_fields
      photo.save(validate: false)
    end
  end

  desc 'Fix date taken for photos without EXIF'
  task fix_taken_at: :environment do
    Photo.unscoped.where(taken_at_from_exif: false).update_all('taken_at = posted_at')
  end

  desc 'Set HTML description for all photos'
  task set_description_html: :environment do
    Photo.unscoped.find_each do |photo|
      photo.send(:set_description_html)
      photo.save(validate: false)
    end
  end
end
