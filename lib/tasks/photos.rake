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
        puts "Processing photo with id = #{photo.id}"
        photo.add_intelligent_derivatives
      end
    end
  end

  desc 'New derivatives'
  task new_derivatives: :environment do
    Photo.unscoped.find_each do |photo|
      puts "Processing photo with id = #{photo.id}"

      attacher = photo.image_attacher

      attacher.remove_derivative(:thumbnail, delete: true) if attacher.derivatives.key?(:thumbnail)

      thumbnail_square = attacher.file.download do |original|
        ImageProcessing::MiniMagick
          .source(original)
          .resize_to_fill!(150, 150)
      end
      attacher.add_derivative(:thumbnail_square, thumbnail_square)

      medium_square = attacher.file.download do |original|
        ImageProcessing::MiniMagick
          .source(original)
          .resize_to_fill!(ENV['PHOTONIA_MEDIUM_SIDE'], ENV['PHOTONIA_MEDIUM_SIDE'])
      end
      attacher.add_derivative(:medium_square, medium_square)

      attacher.atomic_persist
    end
  end
end
