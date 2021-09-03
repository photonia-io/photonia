module Types
  class TagType < Types::BaseObject
    description 'A tag'
    field :id, String, null: false
    field :name, String, null: true
    field :taggings_count, Integer, null: true
    field :photos, [PhotoType], null: true

    def id
      @object.slug
    end

    def photos
      Photo.distinct.tagged_with(@object).order(imported_at: :desc)
    end
  end
end
