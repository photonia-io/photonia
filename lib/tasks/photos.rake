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
  task add_intelligent_derivatives: :environment do
    batch_size = 100

    batch = Photo.unscoped.all.limit(batch_size)
    batch.each do |photo|
      unless photo.image_url(:medium_intelligent)
        puts "Processing photo #{photo.id} / #{photo.slug}"
        photo.add_intelligent_derivatives
      end
    end
  end

  desc 'New derivatives - Step 1'
  task new_derivatives_step_1: :environment do
    Photo.unscoped.where(derivatives_version: 'original').find_each do |photo|
      puts "Adding job for photo #{photo.id} / #{photo.slug}"
      NewDerivativesStep1Job.perform_later(photo.id)
    end
  end
end
