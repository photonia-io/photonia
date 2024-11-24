# frozen_string_literal: true

module Types
  # GraphQL Query Type
  class QueryType < GraphQL::Schema::Object
    description 'The query root of this schema'

    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :photos, resolver: Queries::Photos

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
      description 'Find all albums by page'
      argument :page, Integer, 'Page number', required: false
    end

    field :all_albums, [AlbumType], null: false do
      description 'Find all albums'
    end

    field :albums_with_photos, [AlbumType], null: false do
      description 'Find albums that contain the given photos'
      argument :photo_ids, [String], 'IDs of the photos', required: true
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

    field :timezones, [TimezoneType], 'List of timezones', null: false

    field :admin_settings, AdminSettingsType, 'Admin settings', null: false

    field :impression_counts_by_date, [ImpressionType], 'List of impressions grouped by date', null: false do
      description 'Find impression counts by type and date range'
      argument :end_date, GraphQL::Types::ISO8601DateTime, 'End date', required: true
      argument :start_date, GraphQL::Types::ISO8601DateTime, 'Start date', required: true
      argument :type, String, 'Type of impression', required: true
    end

    field :page, PageType, null: false do
      description 'Find a page by ID'
      argument :id, ID, 'ID of the page', required: true
    end

    # Photos

    def photo(id:)
      photo = Photo.includes(:albums, :albums_photos, :comments).friendly.find(id)
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
      pagy, albums = context[:pagy].call(Album.includes(:public_cover_photo).where('public_photos_count > ?', 0).order(created_at: :desc), page:)
      albums.define_singleton_method(:total_pages) { pagy.pages }
      albums.define_singleton_method(:current_page) { pagy.page }
      albums.define_singleton_method(:limit_value) { pagy.limit }
      albums.define_singleton_method(:total_count) { pagy.count }
      albums
    end

    def all_albums
      context[:authorize].call(Album, :create?)
      Album.where(user_id: context[:current_user].id).order(created_at: :desc)
    end

    def albums_with_photos(photo_ids:)
      context[:authorize].call(Album, :create?)
      Album.albums_with_photos(photo_ids:, ids_are_slugs: true, user_id: context[:current_user].id)
    end

    def album(id:)
      album = Album.includes(:albums_photos).friendly.find(id)
      context[:impressionist].call(album, 'graphql', unique: [:session_hash])
      album
    end

    # Homepage

    def latest_photo
      latest_photo = object ? object[:latest_photo] : Photo.order(posted_at: :desc).first
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
      user = context[:current_user]
      raise GraphQL::ExecutionError, 'User not signed in' unless user
      context[:authorize].call(context[:current_user], :edit?)
    end

    # Admin settings

    def admin_settings
      context[:authorize].call(Setting, :edit?)
    end

    # Timezones
    def timezones
      ActiveSupport::TimeZone::MAPPING.map do |name, key|
        { name:, key: }
      end.sort_by { |timezone| timezone[:name] }
    end

    # Impressions
    def impression_counts_by_date(type:, start_date:, end_date:)
      context[:authorize].call(Impression, :index?)
      Impression.where(impressionable_type: impressionable_type(type))
                .where(created_at: start_date..end_date)
                .group_by_day(:created_at, range: start_date..end_date, format: '%Y-%m-%d')
                .count
                .map { |date, count| { date:, count: } }
    end

    # Pages
    def page(id:)
      title, markdown = PageService.fetch_page(id)

      { title: title, content: Kramdown::Document.new(markdown).to_html.html_safe }
    end

    private

    def impressionable_type(type)
      raise GraphQL::ExecutionError, "Invalid impression type: #{type}" unless %w[Photo Tag Album].include?(type)
      type == 'Tag' ? 'ActsAsTaggableOn::Tag' : type
    end
  end
end
