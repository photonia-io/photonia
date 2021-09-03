module Types
  class PhotoType < Types::BaseObject
    description 'A Photo'

    field :id, String, null: false
    field :name, String, null: true
    field :description, String, null: true
    field :imported_at, GraphQL::Types::ISO8601DateTime, null: true
    field :date_taken, GraphQL::Types::ISO8601DateTime, null: true
    field :license, String, null: true
    field :user_tags, [TagType], null: true
    field :rekognition_tags, [TagType], null: true
    field :albums, [AlbumType], null: true

    def id
      @object.slug
    end

    def user_tags
      @object.tags.rekognition(false)
    end

    def rekognition_tags
      @object.tags.rekognition(true)
    end

    def albums
      @object.albums
    end
  end
end
