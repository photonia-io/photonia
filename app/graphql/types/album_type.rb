# frozen_string_literal: true

module Types
  # GraphQL Album Type
  class AlbumType < Types::BaseObject
    description 'An album'

    field :id, String, null: false
    field :title, String, null: true
    field :description, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :photos_count, Integer, null: false
    field :cover_photo, PhotoType, null: true

    field :photos, [PhotoType], null: false

    def photos
      @object.photos.order(:ordering)
    end

    field :previous_photo_in_album, PhotoType, null: true do
      argument :photo_id, ID, required: true
    end

    field :next_photo_in_album, PhotoType, null: true do
      argument :photo_id, ID, required: true
    end

    def id
      @object.slug
    end

    def photos_count
      @object.albums_photos.size
    end

    def cover_photo
      @object&.photos&.first
    end

    def previous_photo_in_album(photo_id:)
      Photo.friendly.find(photo_id).prev_in_album(@object)
    end

    def next_photo_in_album(photo_id:)
      Photo.friendly.find(photo_id).next_in_album(@object)
    end
  end
end
