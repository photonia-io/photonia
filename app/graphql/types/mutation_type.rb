# frozen_string_literal: true

module Types
  # GraphQL Mutation Type
  class MutationType < GraphQL::Schema::Object
    description 'The mutation root of this schema'

    field :delete_photo, PhotoType, null: false do
      description 'Delete photo'
      argument :id, String, 'Photo Id', required: true
    end

    field :delete_photos, [PhotoType], null: false do
      description 'Delete photos'
      argument :ids, [String], 'Photo Ids', required: true
    end

    field :sign_in, UserType, null: true do
      description 'Sign in'
      argument :email, String, 'User email', required: true
      argument :password, String, 'User password', required: true
    end

    field :sign_out, UserType, null: true do
      description 'Sign out'
    end

    field :update_photo_title, PhotoType, null: false do
      description 'Update photo title'
      argument :id, String, 'Photo Id', required: true
      argument :title, String, 'New photo title', required: true
    end

    field :update_photo_description, PhotoType, null: false do
      description 'Update photo description'
      argument :description, String, 'New photo description', required: true
      argument :id, String, 'Photo Id', required: true
    end

    def delete_photo(id:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :destroy?)
      photo.destroy
      photo
    end

    def delete_photos(ids:)
      deleted_photos = []
      ids.each do |id|
        photo = Photo.friendly.find(id)
        context[:authorize].call(photo, :destroy?)
        puts 'destroying photo with id: ' + id
        # photo.destroy
        deleted_photos << photo
      end
      deleted_photos
    end

    def sign_in(email:, password:)
      user = User.find_for_database_authentication(email:)
      return unless user&.valid_password?(password)

      context[:sign_in].call(:user, user)
      user
    end

    def sign_out
      context[:sign_out].call(context[:current_user])
      {
        id: nil,
        email: nil
      }
    end

    def update_photo_title(id:, title:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      photo.update(name: title)
      photo
    end

    def update_photo_description(id:, description:)
      photo = Photo.friendly.find(id)
      context[:authorize].call(photo, :update?)
      photo.update(description:)
      photo
    end
  end
end
