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
      puts "Processing photo #{photo.id} / #{photo.slug}"

      attacher = photo.image_attacher

      attacher.remove_derivative(:thumbnail, delete: true) if attacher.derivatives.key?(:thumbnail)

      unless attacher.derivatives.key?(:thumbnail_square)
        thumbnail_square = attacher.file.download do |original|
          ImageProcessing::MiniMagick
            .source(original)
            .resize_to_fill!(ENV['PHOTONIA_THUMBNAIL_SIDE'], ENV['PHOTONIA_THUMBNAIL_SIDE'])
        end
        attacher.add_derivative(:thumbnail_square, thumbnail_square)
      end

      unless attacher.derivatives.key?(:thumbnail_square)
        medium_square = attacher.file.download do |original|
          ImageProcessing::MiniMagick
            .source(original)
            .resize_to_fill!(ENV['PHOTONIA_MEDIUM_SIDE'], ENV['PHOTONIA_MEDIUM_SIDE'])
        end
        attacher.add_derivative(:medium_square, medium_square)
      end

      attacher.atomic_persist

      photo.update_attribute(:derivatives_version, 'step_1')
    end
  end
end
