module Mutations
  class UpdatePhotoTitle < Mutations::BaseMutation
    description 'Update photo title'

    argument :id, String, 'Photo Id', required: true
    argument :title, String, 'New photo title', required: true

    type Types::PhotoType, null: false

    def resolve(id:, title:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      if photo.update(title: title)
        photo
      else
        handle_photo_update_errors(photo)
      end
    end
  end
end
