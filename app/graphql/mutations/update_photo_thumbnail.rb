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
      width = (pixel_width * thumbnail[:width]).to_i
      height = (pixel_height * thumbnail[:height]).to_i
      
      thumbnail_hash['x'] = x
      thumbnail_hash['y'] = y
      thumbnail_hash['pixel_width'] = width
      thumbnail_hash['pixel_height'] = height
      
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
