# frozen_string_literal: true

module Types
  # GraphQL Album Type
  class AlbumType < Types::BaseObject
    description 'An album'

    field :id, String, 'Id of the album', null: false

    field :previous_photo_in_album, PhotoType, 'Previous photo in the album', null: true do
      argument :photo_id, ID, 'Id of the photo for which the previous photo is to be found', required: true
    end

    field :next_photo_in_album, PhotoType, 'Next photo in the album', null: true do
      argument :photo_id, ID, 'Id of the photo for which the next photo is to be found', required: true
    end

    field :can_edit, Boolean, 'Whether the current user can edit the album', null: false
    field :contained_photos_count, Integer, 'Number of photos (from the provided list) contained in the album', null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, 'Creation datetime of the album', null: false
    field :description, String, 'Description of the album', null: true
    field :description_html, String, 'HTML description of the album', null: true
    field :photos_count, Integer, 'Total number of photos in the album', null: false
    field :public_cover_photo, PhotoType, 'Public cover photo of the album', null: true
    field :public_photos_count, Integer, 'Number of public photos in the album', null: false
    field :title, String, 'Title of the album', null: false

    field :photos, Types::PaginatedPhotoType, null: false do
      argument :page, Integer, 'Page number', required: false
      description 'Photos in the album'
    end

    def photos(page: nil)
      pagy, @photos = context[:pagy].call(@object.photos.order(:ordering), page:)
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.limit }
      @photos.define_singleton_method(:total_count) { pagy.count }
      @photos
    end

    def id
      @object.slug
    end

    def photos_count
      context[:authorize].call(@object, :update?)
      @object.photos_count
    end

    def public_cover_photo
      @object.public_cover_photo
    end

    def previous_photo_in_album(photo_id:)
      Photo.friendly.find(photo_id).prev_in_album(@object)
    end

    def next_photo_in_album(photo_id:)
      Photo.friendly.find(photo_id).next_in_album(@object)
    end

    def can_edit
      context[:authorize].call(@object, :update?)
    end
  end
end
