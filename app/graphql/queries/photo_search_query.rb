# frozen_string_literal: true

module Queries
  # Advanced photo search: filters, sort, and pagination (#1101)
  class PhotoSearchQuery < BaseQuery
    description 'Find photos matching advanced search filters'

    type Types::PaginatedPhotoType, null: false

    argument :filters, Types::PhotoSearchFiltersInput, 'Search filters', required: true
    argument :sort, Types::PhotoSortField, 'Field to sort by', required: false, default_value: 'relevance'
    argument :direction, Types::SortDirection, 'Sort direction', required: false, default_value: 'desc'
    argument :page, Integer, 'Page number', required: false

    def resolve(filters:, sort:, direction:, page: nil)
      filters_hash = filters.to_h.compact_blank

      base = Pundit.policy_scope(current_user, Photo.unscoped)
      album_scope = Pundit.policy_scope(current_user, Album.unscoped)
      relation = PhotoSearch.new(base, filters_hash, sort:, direction:, album_scope:).relation

      pagy, photos = context[:pagy].call(relation, page:)
      add_pagination_methods(photos, pagy)
      record_search(query: filters_hash[:query], results_count: pagy.count, page:,
                     filters: filters_hash.except(:query).presence)
      photos
    end
  end
end
