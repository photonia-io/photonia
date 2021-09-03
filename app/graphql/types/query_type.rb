module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :photo, PhotoType, null: false do
      description 'Find a photo by ID'
      argument :id, ID, required: true
    end

    def photo(id:)
      Photo.friendly.find(id)
    end

    field :tag, TagType, null: false do
      description 'Find a tag by ID'
      argument :id, ID, required: true
    end

    def tag(id:)
      ActsAsTaggableOn::Tag.friendly.find(id)
    end

    field :album, AlbumType, null: false do
      description 'Find an album by ID'
      argument :id, ID, required: true
    end

    def album(id:)
      Album.friendly.find(id)
    end

    field :homepage, HomepageType, null: false, description: 'Get homepage data'

    def homepage
      {
        latest_photo: Photo.order(imported_at: :desc).first,
        random_photo: Photo.order(Arel.sql('RANDOM()')).first,
        most_used_tags: ActsAsTaggableOn::Tag.photonia_most_used(limit: 60)
      }
    end
  end
end
