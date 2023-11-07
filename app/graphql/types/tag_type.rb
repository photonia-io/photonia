# frozen_string_literal: true

module Types
  # GraphQL Tag Type
  class TagType < Types::BaseObject
    description 'A tag'
    field :id, String, 'ID of the tag', null: false
    field :name, String, 'Name of the tag', null: true
    field :photos, Types::PhotoType.collection_type, 'Photos tagged with this tag', null: true do
      argument :page, Integer, 'Page number', required: false
    end
    field :taggings_count, Integer, 'Number of photos tagged with this tag', null: true

    def id
      @object.slug
    end

    def photos(page: nil)
      pagy, @photos = context[:pagy].call(Photo.distinct.tagged_with(@object).order(posted_at: :desc), page:)
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.items }
      @photos.define_singleton_method(:total_count) { pagy.count }
      @photos
    end
  end
end
