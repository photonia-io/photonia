module Mutations
  class UpdatePhotoLicense < Mutations::BaseMutation
    description 'Update photo license'

    argument :id, String, 'Photo Id', required: true
    argument :license, String, 'New photo license', required: false

    type Types::PhotoType, null: false

    def resolve(id:, license:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      if photo.update(license: license)
        photo
      else
        handle_photo_update_errors(photo)
      end
    end
  end
end
