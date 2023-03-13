# frozen_string_literal: true

module Types
  # GraphQL Query Type
  class QueryType < GraphQL::Schema::Object
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Photos

    field :photos, Types::PhotoType.collection_type, null: false do
      description 'Find all photos'
      argument :page, Integer, required: false      
    end

    def photos(page: nil)
      pagy, @photos = context[:pagy].call(Photo.all.order(imported_at: :desc), page: page)
      @photos.define_singleton_method(:total_pages) { pagy.pages }
      @photos.define_singleton_method(:current_page) { pagy.page }
      @photos.define_singleton_method(:limit_value) { pagy.items }
      @photos.define_singleton_method(:total_count) { pagy.count }
      @photos
    end

    field :photo, PhotoType, null: false do
      description 'Find a photo by ID'
      argument :id, ID, required: true
    end

    def photo(id:)
      Photo.includes(:albums).includes(:albums_photos).friendly.find(id)
    end

    # Tags

    field :tag, TagType, null: false do
      description 'Find a tag by ID'
      argument :id, ID, required: true
      argument :page, Integer, required: false
    end

    def tag(id:)
      ActsAsTaggableOn::Tag.friendly.find(id)
    end

    field :most_used_user_tags, [TagType], null: false do
      description 'Find the most used user tags'
    end

    def most_used_user_tags
      ActsAsTaggableOn::Tag.photonia_most_used
    end

    field :least_used_user_tags, [TagType], null: false do
      description 'Find the least used user tags'
    end

    def least_used_user_tags
      ActsAsTaggableOn::Tag.photonia_least_used
    end

    field :most_used_machine_tags, [TagType], null: false do
      description 'Find the most used machine tags'
    end

    def most_used_machine_tags
      ActsAsTaggableOn::Tag.photonia_most_used(rekognition: true)
    end

    field :least_used_machine_tags, [TagType], null: false do
      description 'Find the least used machine tags'
    end

    def least_used_machine_tags
      ActsAsTaggableOn::Tag.photonia_least_used(rekognition: true)
    end

    # Albums

    field :albums, Types::AlbumType.collection_type, null: false do
      description 'Find all albums'
      argument :page, Integer, required: false
    end

    def albums(page: nil)
      pagy, @albums = context[:pagy].call(Album.includes(:albums_photos, :photos).order(created_at: :desc), page: page)
      @albums.define_singleton_method(:total_pages) { pagy.pages }
      @albums.define_singleton_method(:current_page) { pagy.page }
      @albums.define_singleton_method(:limit_value) { pagy.items }
      @albums.define_singleton_method(:total_count) { pagy.count }
      @albums
    end

    field :album, AlbumType, null: false do
      description 'Find an album by ID'
      argument :id, ID, required: true
      argument :page, Integer, required: false
    end

    def album(id:)
      Album.includes(:albums_photos).friendly.find(id)
    end

    # Homepage

    field :latest_photo, PhotoType, null: false

    def latest_photo
      object ? object[:latest_photo] : Photo.order(imported_at: :desc).first
    end

    field :random_photo, PhotoType, null: false

    def random_photo
      object ? object[:random_photo] : Photo.order(Arel.sql('RANDOM()')).first
    end

    field :most_used_tags, [TagType], null: false

    def most_used_tags
      object ? object[:most_used_tags] : ActsAsTaggableOn::Tag.photonia_most_used(limit: 60)
    end

    # Users

    field :user_settings, UserType, null: false

    def user_settings
      context[:current_user]
    end
  end
end
