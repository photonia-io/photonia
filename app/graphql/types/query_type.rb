# frozen_string_literal: true

module Types
  # GraphQL Query Type
  class QueryType < GraphQL::Schema::Object
    description 'The query root of this schema'

    field :admin_settings, resolver: Queries::AdminSettingsQuery, description: 'Get admin settings'
    field :album, resolver: Queries::AlbumQuery, description: 'Find an album by ID'
    field :album_spotlight, resolver: Queries::AlbumSpotlightQuery, description: 'The album spotlighted on the homepage'
    field :albums, resolver: Queries::AlbumsQuery, description: 'Find all albums by page'
    field :cameras, resolver: Queries::CamerasQuery, description: 'List cameras used by visible photos'
    field :current_user, resolver: Queries::CurrentUserQuery, description: 'Get the current user'
    field :user, resolver: Queries::UserQuery, description: 'Find a user by ID (admin only)'
    field :users, resolver: Queries::UsersQuery, description: 'List all users (admin only)'
    field :homepage_stats, resolver: Queries::HomepageStatsQuery, description: 'Public archive totals and per-year photo counts'
    field :impression_counts_by_date, resolver: Queries::ImpressionCountsByDateQuery, description: 'Find impression counts by type and date range'
    field :most_viewed_on_date, resolver: Queries::MostViewedOnDateQuery, description: 'Most viewed photos and albums on a date (admin only)'
    field :label_names, resolver: Queries::LabelNamesQuery, description: 'Find label names, prefix-matched'
    field :page, resolver: Queries::PageQuery, description: 'Find a page by ID'
    field :photo, resolver: Queries::PhotoQuery, description: 'Find a photo by ID'
    field :photos, resolver: Queries::PhotosQuery, description: 'Find a list of photos'
    field :photos_by_ids, resolver: Queries::PhotosByIdsQuery, description: 'Find photos by ID (slug), skipping unknown or inaccessible ones'
    field :photo_search, resolver: Queries::PhotoSearchQuery, description: 'Advanced photo search with filters, sort, and pagination'
    field :recent_comments, resolver: Queries::RecentCommentsQuery, description: 'Latest comments on public photos and albums'
    field :related_tags, resolver: Queries::RelatedTagsQuery, description: 'Suggest related tags based on co-occurrence'
    field :search_suggestions, resolver: Queries::SearchSuggestionsQuery, description: 'Suggestions for the navbar search box dropdown'
    field :tag, resolver: Queries::TagQuery, description: 'Find a tag by ID'
    field :tags, resolver: Queries::TagsQuery, description: 'Find tags'
    field :timezones, resolver: Queries::TimezonesQuery, description: 'List of timezones'

    # Flickr claim queries
    field :flickr_user_claim, resolver: Queries::FlickrUserClaimQuery, description: 'Find a Flickr user claim by ID'
    field :my_flickr_claims, resolver: Queries::MyFlickrClaimsQuery, description: 'Get current user\'s Flickr claims'
    field :pending_flickr_claims, resolver: Queries::PendingFlickrClaimsQuery, description: 'Get pending Flickr claims (admin only)'
  end
end
