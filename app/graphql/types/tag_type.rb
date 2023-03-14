module Types
  class TagType < Types::BaseObject
    description 'A tag'
    field :id, String, null: false
    field :name, String, null: true
    field :taggings_count, Integer, null: true
    field :photos, Types::PhotoType.collection_type, null: true do
      argument :page, Integer, required: false
    end

    def id
      @object.slug
    end

    def photos(page: nil)
      pagy, @photos = context[:pagy].call(Photo.distinct.tagged_with(@object).order(imported_at: :desc), page: page)
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.items }
      @photos.define_singleton_method(:total_count) { pagy.count }
      @photos
    end
  end
end
