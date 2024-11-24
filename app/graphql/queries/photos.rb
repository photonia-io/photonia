# frozen_string_literal: true

module Queries
  class Photos < Queries::BaseQuery
    description 'Find all photos or photos matching a query'

    argument :page, Integer, 'Page number', required: false
    argument :query, String, 'Search query', required: false

    type Types::PhotoType.collection_type, null: false

    def resolve(page: nil, query: nil)
      pagy, photos = context[:pagy].call(
        query.present? ? Photo.search(query) : Photo.order(posted_at: :desc),
        page:
      )
      photos.define_singleton_method(:total_pages) { pagy.pages }
      photos.define_singleton_method(:current_page) { pagy.page }
      photos.define_singleton_method(:limit_value) { pagy.limit }
      photos.define_singleton_method(:total_count) { pagy.count }
      photos
    end
  end
end
