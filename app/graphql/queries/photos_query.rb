# frozen_string_literal: true

module Queries
  # Get all photos or photos matching a query
  class PhotosQuery < Queries::BaseQuery
    description 'Find all photos or photos matching a query'

    type Types::PaginatedPhotoType, null: false

    argument :mode, String, 'Mode of operation ("paginated" or "simple")', required: false, default_value: 'paginated'

    # Paginated mode arguments
    argument :page, Integer, 'Page number. Applies to the paginated mode of operation.', required: false
    argument :query, String, 'Search query. Applies to the paginated mode of operation.', required: false

    # Simple mode arguments
    argument :fetch_type, String, 'How to fetch photos ("latest" or "random"). Applies to the simple mode of operation.', required: false, default_value: 'latest'
    argument :limit, Integer, 'Number of photos to return. Applies to the simple mode of operation. Maximum of 100 photos.', required: false

    MAX_LIMIT = ENV.fetch('PHOTOS_QUERY_MAX_LIMIT', 100).to_i

    def resolve(mode: nil, fetch_type: nil, limit: nil, page: nil, query: nil)
      if mode == 'paginated'
        paginated_photos(query, page)
      else
        simple_photos(fetch_type, limit)
      end
    end

    private

    def paginated_photos(query, page)
      pagy, photos = context[:pagy].call(
        query.present? ? Photo.search(query) : Photo.order(posted_at: :desc),
        page:
      )
      add_pagination_methods(photos, pagy)
      photos
    end

    def simple_photos(fetch_type, limit)
      # Determine the effective limit (apply MAX_LIMIT when not specified or when exceeding maximum)
      effective_limit = determine_effective_limit(limit)

      photos = if fetch_type == 'random'
                 Photo.order('RANDOM()')
               else
                 Photo.order(posted_at: :desc)
               end
      photos = photos.limit(effective_limit)
      add_dummy_pagination_methods(photos)
      photos
    end

    def determine_effective_limit(limit)
      [limit || MAX_LIMIT, MAX_LIMIT].min
    end
  end
end
