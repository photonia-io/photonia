# frozen_string_literal: true

module Queries
  # Get all photos or photos matching a query
  class PhotosQuery < Queries::BaseQuery
    type Types::PhotoType.collection_type, null: false
    description 'Find all photos or photos matching a query'

    argument :page, Integer, 'Page number', required: false
    argument :query, String, 'Search query', required: false

    def resolve(page: nil, query: nil)
      pagy, photos = context[:pagy].call(
        query.present? ? Photo.search(query) : Photo.order(posted_at: :desc),
        page:
      )
      add_pagination_methods(photos, pagy)
      photos
    end
  end
end
