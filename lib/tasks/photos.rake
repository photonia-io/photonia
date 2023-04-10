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
end
