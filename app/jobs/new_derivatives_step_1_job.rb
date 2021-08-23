class NewDerivativesStep1Job < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.find(photo_id)
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
