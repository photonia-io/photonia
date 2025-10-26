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

    # Maximum limit for simple mode queries. Defaults to 100 in production.
    SIMPLE_MODE_MAX_LIMIT = 100

    def resolve(mode: nil, fetch_type: nil, limit: nil, page: nil, query: nil)
      if mode == 'paginated'
        paginated_photos(query, page)
      else
        simple_photos(fetch_type, limit)
      end
    end

    private

    def paginated_photos(query, page)
      # Use Pundit policy scope to decide visibility:
      # - visitor: only public photos
      # - logged in: public photos + own photos (any privacy)
      # - admin: all photos
      base = Pundit.policy_scope(current_user, Photo.unscoped)

      relation =
        if query.present?
          base.search(query)
        else
          base.order(posted_at: :desc)
        end

      pagy, photos = context[:pagy].call(
        relation,
        page:
      )
      add_pagination_methods(photos, pagy)
      photos
    end

    def simple_photos(fetch_type, limit)
      # Use Pundit policy scope for simple mode too
      base = Pundit.policy_scope(current_user, Photo.unscoped)

      photos =
        if fetch_type == 'random'
          base.order('RANDOM()')
        else
          base.order(posted_at: :desc)
        end

      photos = photos.limit(effective_limit(limit))
      add_dummy_pagination_methods(photos)
      photos
    end

    # Determine the effective limit (apply MAX_LIMIT when not specified or when exceeding maximum)
    def effective_limit(limit)
      (limit || SIMPLE_MODE_MAX_LIMIT).clamp(0, SIMPLE_MODE_MAX_LIMIT)
    end
  end
end
