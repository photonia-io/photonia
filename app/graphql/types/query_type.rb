# frozen_string_literal: true

module Types
  # GraphQL Query Type
  class QueryType < GraphQL::Schema::Object
    description 'The query root of this schema'

    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :photos, Types::PhotoType.collection_type, null: false do
      description 'Find all photos or photos matching a query'
      argument :page, Integer, 'Page number', required: false
      argument :query, String, 'Search query', required: false
    end

    field :photo, PhotoType, null: false do
      description 'Find a photo by ID'
      argument :id, ID, 'ID of the photo', required: true
    end

    field :tag, TagType, null: false do
      description 'Find a tag by ID'
      argument :id, ID, 'ID of the tag', required: true
      argument :page, Integer, 'Page number', required: false
    end

    field :most_used_user_tags, [TagType], null: false do
      description 'Find the most used user tags'
    end

    field :least_used_user_tags, [TagType], null: false do
      description 'Find the least used user tags'
    end

    field :most_used_machine_tags, [TagType], null: false do
      description 'Find the most used machine tags'
    end

    field :least_used_machine_tags, [TagType], null: false do
      description 'Find the least used machine tags'
    end

    field :albums, Types::AlbumType.collection_type, null: false do
      description 'Find all albums'
      argument :page, Integer, 'Page number', required: false
    end

    field :album, AlbumType, null: false do
      description 'Find an album by ID'
      argument :id, ID, 'ID of the album', required: true
      argument :page, Integer, 'Page number', required: false
    end

    field :latest_photo, PhotoType, 'Latest photo', null: false

    field :random_photos, [PhotoType], 'Random photos', null: false

    field :most_used_tags, [TagType], 'List of most used tags', null: false

    field :user_settings, UserType, 'User settings', null: false

    # Photos

    def photos(page: nil, query: nil)
      pagy, photos = context[:pagy].call(
        query.present? ? Photo.search(query) : Photo.all.order(imported_at: :desc),
        page:
      )
      photos.define_singleton_method(:total_pages) { pagy.pages }
      photos.define_singleton_method(:current_page) { pagy.page }
      photos.define_singleton_method(:limit_value) { pagy.items }
      photos.define_singleton_method(:total_count) { pagy.count }
      photos
    end

    def photo(id:)
      photo = Photo.includes(:albums).includes(:albums_photos).friendly.find(id)
      context[:impressionist].call(photo, 'graphql', unique: [:session_hash])
      photo
    end

    # Tags

    def tag(id:)
      tag = ActsAsTaggableOn::Tag.friendly.find(id)
      context[:impressionist].call(tag, 'graphql', unique: [:session_hash])
      tag
    end

    def most_used_user_tags
      ActsAsTaggableOn::Tag.photonia_most_used
    end

    def least_used_user_tags
      ActsAsTaggableOn::Tag.photonia_least_used
    end

    def most_used_machine_tags
      ActsAsTaggableOn::Tag.photonia_most_used(rekognition: true)
    end

    def least_used_machine_tags
      ActsAsTaggableOn::Tag.photonia_least_used(rekognition: true)
    end

    # Albums

    def albums(page: nil)
      pagy, albums = context[:pagy].call(Album.includes(:albums_photos, :photos).order(created_at: :desc), page:)
      albums.define_singleton_method(:total_pages) { pagy.pages }
      albums.define_singleton_method(:current_page) { pagy.page }
      albums.define_singleton_method(:limit_value) { pagy.items }
      albums.define_singleton_method(:total_count) { pagy.count }
      albums
    end

    def album(id:)
      album = Album.includes(:albums_photos).friendly.find(id)
      context[:impressionist].call(album, 'graphql', unique: [:session_hash])
      album
    end

    # Homepage

    def latest_photo
      latest_photo = object ? object[:latest_photo] : Photo.order(imported_at: :desc).first
      context[:impressionist].call(latest_photo, 'graphql', unique: [:session_hash])
      latest_photo
    end

    def random_photos
      Photo.order(Arel.sql('RANDOM()')).limit(4)
    end

    def most_used_tags
      object ? object[:most_used_tags] : ActsAsTaggableOn::Tag.photonia_most_used(limit: 60)
    end

    # Users

    def user_settings
      context[:current_user]
    end
  end
end
