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
    field :photos_count, Integer, 'Total number of photos in the album (public and private)', null: false
    field :privacy, String, 'Privacy level of the album', null: false
    field :public_cover_photo, PhotoType, 'Public cover photo of the album', null: true
    field :public_photos_count, Integer, 'Number of public photos in the album', null: false
    field :sorting_order, String, 'Sorting order of the album', null: false
    field :sorting_type, String, 'Sorting type of the album', null: false
    field :title, String, 'Title of the album', null: false

    field :all_photos, [PhotoType], 'All photos in the album', null: false

    field :photos, Types::PaginatedPhotoType, null: false do
      argument :page, Integer, 'Page number', required: false
      description 'Photos in the album'
    end

    def all_photos
      context[:authorize].call(@object, :update?)
      context[:album] = @object
      @object.all_photos(select: false, refetch: true).includes(:albums_photos)
    end

    def photos(page: nil)
      pagy, @photos = context[:pagy].call(
        scoped_album_photos.order(:ordering),
        page:
      )
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.limit }
      @photos.define_singleton_method(:total_count) { pagy.count }
      context[:album] = @object
      @photos
    end

    def id
      @object.slug
    end

    def photos_count
      context[:authorize].call(@object, :update?)
      @object.photos_count
    end

    delegate :public_cover_photo, to: :@object

    def previous_photo_in_album(photo_id:)
      scoped_photo_ordering = scoped_photo_ordering(photo_id)
      scoped_previous_photo = scoped_previous_photo(scoped_photo_ordering)
      return nil if scoped_previous_photo.nil?

      context[:authorize].call(scoped_previous_photo, :show?)
    end

    def next_photo_in_album(photo_id:)
      scoped_photo_ordering = scoped_photo_ordering(photo_id)
      scoped_next_photo = scoped_next_photo(scoped_photo_ordering)
      return nil if scoped_next_photo.nil?

      context[:authorize].call(scoped_next_photo, :show?)
    end

    def can_edit
      Pundit.policy(context[:current_user], @object)&.edit?
    end

    def sorting_type
      @object.graphql_sorting_type
    end

    private

    def scoped_photo_ordering(photo_id)
      base = Pundit.policy_scope(context[:current_user], Photo.unscoped)
      base.friendly.find(photo_id).albums_photos.find_by(album_id: @object.id).ordering
    end

    def scoped_album_photos
      Pundit.policy_scope(context[:current_user], @object.photos.unscope(where: :privacy))
    end

    def scoped_next_photo(current_ordering)
      scoped_album_photos.joins(:albums_photos)
                         .where('albums_photos.ordering > ?', current_ordering)
                         .order('albums_photos.ordering ASC')
                         .first
    end

    def scoped_previous_photo(current_ordering)
      scoped_album_photos.joins(:albums_photos)
                         .where(albums_photos: { ordering: ...current_ordering })
                         .order('albums_photos.ordering DESC')
                         .first
    end
  end
end
