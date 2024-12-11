# frozen_string_literal: true

module Types
  # GraphQL Query Type
  class QueryType < GraphQL::Schema::Object
    description 'The query root of this schema'

    field :admin_settings, resolver: Queries::AdminSettingsQuery, description: 'Get admin settings'
    field :album, resolver: Queries::AlbumQuery, description: 'Find an album by ID'
    field :albums, resolver: Queries::AlbumsQuery, description: 'Find all albums by page'
    field :current_user, resolver: Queries::CurrentUserQuery, description: 'Get the current user'
    field :impression_counts_by_date, resolver: Queries::ImpressionCountsByDateQuery, description: 'Find impression counts by type and date range'
    field :page, resolver: Queries::PageQuery, description: 'Find a page by ID'
    field :photo, resolver: Queries::PhotoQuery, description: 'Find a photo by ID'
    field :photos, resolver: Queries::PhotosQuery, description: 'Find a list of photos'
    field :tag, resolver: Queries::TagQuery, description: 'Find a tag by ID'
    field :tags, resolver: Queries::TagsQuery, description: 'Find tags'
    field :timezones, resolver: Queries::TimezonesQuery, description: 'List of timezones'
  end
end
