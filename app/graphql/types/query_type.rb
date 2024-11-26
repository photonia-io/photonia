# frozen_string_literal: true

module Types
  # GraphQL Query Type
  class QueryType < GraphQL::Schema::Object
    description 'The query root of this schema'

    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    # include GraphQL::Types::Relay::HasNodeField
    # include GraphQL::Types::Relay::HasNodesField

    field :album, resolver: Queries::AlbumQuery, description: 'Find an album by ID'
    field :albums, resolver: Queries::AlbumsQuery, description: 'Find all albums by page'
    field :current_user, resolver: Queries::CurrentUserQuery, description: 'Get the current user'
    field :photo, resolver: Queries::PhotoQuery, description: 'Find a photo by ID'
    field :photos, resolver: Queries::PhotosQuery, description: 'Find all photos or photos matching a query'
    field :tag, resolver: Queries::TagQuery, description: 'Find a tag by ID'
    field :tags, resolver: Queries::TagsQuery, description: 'Find tags'

    field :latest_photo, PhotoType, 'Latest photo', null: false

    field :random_photos, [PhotoType], 'Random photos', null: false

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

    # Homepage

    def latest_photo
      latest_photo = object ? object[:latest_photo] : Photo.order(posted_at: :desc).first
      context[:impressionist].call(latest_photo, 'graphql', unique: [:session_hash])
      latest_photo
    end

    def random_photos
      Photo.order(Arel.sql('RANDOM()')).limit(4)
    end

    # Admin settings

    def admin_settings
      context[:authorize].call(Setting, :edit?)
    end

    # Timezones
    def timezones
      timezones = ActiveSupport::TimeZone::MAPPING.map do |name, key|
        { name:, key: }
      end
      timezones.sort_by { |timezone| timezone[:name] }
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

      { title: title, content: MarkdownToHtml.new(markdown).to_html }
    end

    private

    def impressionable_type(type)
      raise GraphQL::ExecutionError, "Invalid impression type: #{type}" unless %w[Photo Tag Album].include?(type)

      type == 'Tag' ? 'ActsAsTaggableOn::Tag' : type
    end
  end
end
