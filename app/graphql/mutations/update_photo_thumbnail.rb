module Mutations
  class UpdatePhotoThumbnail < Mutations::BaseMutation
    description 'Update photo user-defined thumbnail'

    argument :id, String, 'Photo Id', required: true
    argument :thumbnail, Types::UserThumbnailInput, 'User-defined thumbnail bounding box', required: true

    type Types::PhotoType, null: false

    def resolve(id:, thumbnail:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      
      # Convert thumbnail to hash with string keys for JSONB storage
      thumbnail_hash = {
        'top' => thumbnail[:top],
        'left' => thumbnail[:left],
        'width' => thumbnail[:width],
        'height' => thumbnail[:height]
      }
      
      # Calculate pixel coordinates for derivatives
      pixel_width = photo.pixel_width
      pixel_height = photo.pixel_height
      x = (pixel_width * thumbnail[:left]).to_i
      y = (pixel_height * thumbnail[:top]).to_i
      
      # Calculate the square size in pixels
      # The thumbnail dimensions are percentages that should produce a square
      width_px = (pixel_width * thumbnail[:width]).to_i
      height_px = (pixel_height * thumbnail[:height]).to_i
      # Use the smaller dimension to ensure it's actually square
      square_size = [width_px, height_px].min
      
      thumbnail_hash['x'] = x
      thumbnail_hash['y'] = y
      thumbnail_hash['pixel_width'] = square_size
      thumbnail_hash['pixel_height'] = square_size
      
      if photo.update(user_thumbnail: thumbnail_hash)
        # Regenerate derivatives with new user thumbnail
        AddIntelligentDerivativesJob.perform_later(photo.id)
        photo
      else
        handle_photo_update_errors(photo)
      end
    end
  end
end
