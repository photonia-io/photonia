# frozen_string_literal: true

class NewDerivativesStep1Job < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.unscoped.find(photo_id)
    attacher = photo.image_attacher

    attacher.remove_derivative(:thumbnail, delete: true) if attacher.derivatives.key?(:thumbnail)

    unless attacher.derivatives.key?(:thumbnail_square)
      thumbnail_square = attacher.file.download do |original|
        ImageProcessing::MiniMagick
          .source(original)
          .resize_to_fill!(
            ENV.fetch('PHOTONIA_THUMBNAIL_SIDE', nil),
            ENV.fetch('PHOTONIA_THUMBNAIL_SIDE', nil)
          )
      end
      attacher.add_derivative(:thumbnail_square, thumbnail_square)
    end

    unless attacher.derivatives.key?(:medium_square)
      medium_square = attacher.file.download do |original|
        ImageProcessing::MiniMagick
          .source(original)
          .resize_to_fill!(
            ENV.fetch('PHOTONIA_MEDIUM_SIDE', nil),
            ENV.fetch('PHOTONIA_MEDIUM_SIDE', nil)
          )
      end
      attacher.add_derivative(:medium_square, medium_square)
    end

    attacher.atomic_persist
    photo.update_attribute(:derivatives_version, 'step_1')
  end
end
