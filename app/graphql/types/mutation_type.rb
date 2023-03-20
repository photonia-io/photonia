# frozen_string_literal: true

module Types
  class MutationType < GraphQL::Schema::Object
    field :sign_in, UserType, null: true do
      description 'Sign in'
      argument :email, String, required: true
      argument :password, String, required: true
    end

    field :sign_out, UserType, null: true do
      description 'Sign out'
    end

    field :update_photo_title, PhotoType, null: false do
      description 'Update photo title'
      argument :id, String, required: true
      argument :title, String, required: true
    end

    field :update_photo_description, PhotoType, null: false do
      description 'Update photo description'
      argument :description, String, required: true
      argument :id, String, required: true
    end

    def sign_in(email:, password:)
      user = User.find_for_database_authentication(email:)
      return unless user&.valid_password?(password)

      context[:sign_in].call(:user, user)
      user
    end

    def sign_out
      context[:sign_out].call(context[:current_user])
      user = {
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
