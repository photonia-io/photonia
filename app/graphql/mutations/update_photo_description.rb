module Mutations
  class UpdatePhotoDescription < Mutations::BaseMutation
    description 'Update photo description'

    argument :id, String, 'Photo Id', required: true
    argument :description, String, 'New photo description', required: true

    type Types::PhotoType, null: false

    def resolve(id:, description:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      if photo.update(description: description)
        photo
      else
        handle_photo_update_errors(photo)
      end
    end
  end
end
