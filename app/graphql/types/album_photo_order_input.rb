# frozen_string_literal: true

module Types
  # GraphQL Input Type for reordering photos in an album
  class AlbumPhotoOrderInput < Types::BaseInputObject
    description 'Input type for reordering photos in an album'

    argument :ordering, Integer, required: true, description: 'New ordering value for the photo in the album'
    argument :photo_id, ID, required: true, description: 'ID of the photo to be reordered'
  end
end
