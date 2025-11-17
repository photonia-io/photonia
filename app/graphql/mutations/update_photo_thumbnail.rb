module Mutations
  class UpdatePhotoThumbnail < Mutations::BaseMutation
    description 'Update photo user-defined thumbnail'

    argument :id, String, 'Photo Id', required: true
    argument :thumbnail, Types::UserThumbnailInput, 'User-defined thumbnail bounding box', required: true

    type Types::PhotoType, null: false

    def resolve(id:, thumbnail:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)

      # Validate thumbnail percentages
      validate_thumbnail_percentages!(thumbnail)

      # Store only axis-relative percentages (top, left, width, height)
      # Pixel coordinates (x, y, pixel_width, pixel_height) are computed on the fly in Photo#custom_crop
      thumbnail_hash = {
        'top' => thumbnail[:top],
        'left' => thumbnail[:left],
        'width' => thumbnail[:width],
        'height' => thumbnail[:height]
      }

      if photo.update(user_thumbnail: thumbnail_hash)
        # Regenerate derivatives with new user thumbnail
        AddDerivativesJob.perform_later(photo.id)
        photo
      else
        handle_photo_update_errors(photo)
      end
    end

    private

    def validate_thumbnail_percentages!(thumbnail)
      # Validate individual percentage values are within 0.0-1.0
      errors = []

      %i[top left width height].each do |field|
        value = thumbnail[field]
        errors << "#{field.to_s.capitalize} must be between 0.0 and 1.0" if value < 0.0 || value > 1.0
      end

      # Validate boundary constraints
      errors << 'Top + height must not exceed 1.0' if thumbnail[:top] + thumbnail[:height] > 1.0

      errors << 'Left + width must not exceed 1.0' if thumbnail[:left] + thumbnail[:width] > 1.0

      raise GraphQL::ExecutionError, errors.join(', ') if errors.any?
    end
  end
end
