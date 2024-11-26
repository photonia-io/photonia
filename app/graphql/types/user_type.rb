# frozen_string_literal: true

module Types
  # GraphQL User Type
  class UserType < Types::BaseObject
    description 'A user'

    field :admin, Boolean, 'Admin', null: false
    field :albums, [Types::AlbumType], "All of the user's albums", null: false
    field :albums_with_photos, [AlbumType], null: false do
      description 'Find albums that contain the given photos'
      argument :photo_ids, [String], 'IDs of the photos', required: true
    end
    field :display_name, String, 'Full name', null: true
    field :email, String, 'Email', null: true
    field :first_name, String, 'First name', null: true
    field :id, String, 'User ID', null: false
    field :last_name, String, 'Last name', null: true
    field :timezone, Types::TimezoneType, 'Timezone', null: false
    field :uploader, Boolean, 'Uploader', null: false

    def id
      @object.slug
    end

    def albums
      authorize(Album, :create?)
      Album.where(user_id: @object.id).order(created_at: :desc)
    end

    def albums_with_photos(photo_ids:)
      authorize(Album, :create?)
      Album.albums_with_photos(photo_ids:, ids_are_slugs: true, user_id: context[:current_user].id)
    end

    def timezone
      { name: @object.timezone }
    end

    def uploader
      @object.has_role?(:uploader)
    end
  end
end
