# frozen_string_literal: true

module Types
  # GraphQL Query Type
  class QueryType < GraphQL::Schema::Object
    description 'The query root of this schema'

    field :album, resolver: Queries::AlbumQuery, description: 'Find an album by ID'
    field :albums, resolver: Queries::AlbumsQuery, description: 'Find all albums by page'
    field :current_user, resolver: Queries::CurrentUserQuery, description: 'Get the current user'
    field :page, resolver: Queries::PageQuery, description: 'Find a page by ID'
    field :photo, resolver: Queries::PhotoQuery, description: 'Find a photo by ID'
    field :photos, resolver: Queries::PhotosQuery, description: 'Find a list of photos'
    field :tag, resolver: Queries::TagQuery, description: 'Find a tag by ID'
    field :tags, resolver: Queries::TagsQuery, description: 'Find tags'
    field :timezones, resolver: Queries::TimezonesQuery, description: 'List of timezones'

    field :admin_settings, AdminSettingsType, 'Admin settings', null: false

    field :impression_counts_by_date, [ImpressionType], 'List of impressions grouped by date', null: false do
      description 'Find impression counts by type and date range'
      argument :end_date, GraphQL::Types::ISO8601DateTime, 'End date', required: true
      argument :start_date, GraphQL::Types::ISO8601DateTime, 'Start date', required: true
      argument :type, String, 'Type of impression', required: true
    end

    # Admin settings

    def admin_settings
      context[:authorize].call(Setting, :edit?)
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

    private

    def impressionable_type(type)
      raise GraphQL::ExecutionError, "Invalid impression type: #{type}" unless %w[Photo Tag Album].include?(type)

      type == 'Tag' ? 'ActsAsTaggableOn::Tag' : type
    end
  end
end
