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
    argument :fetch_type, String, 'How to fetch photos ("latest", "feed" or "random"). Applies to the simple mode of operation.', required: false, default_value: 'latest'
    argument :limit, Integer, 'Number of photos to return. Applies to the simple mode of operation. Maximum of 100 photos.', required: false
    argument :offset, Integer, 'Number of photos to skip. Applies to the simple mode of operation.', required: false

    # Maximum limit for simple mode queries. Defaults to 100 in production.
    SIMPLE_MODE_MAX_LIMIT = 100

    TOTAL_VIEWS_SQL = '(photos.impressions_count + photos.flickr_impressions_count)'
    TRENDING_WINDOW = 7.days
    TRENDING_POOL = 50
    TRENDING_CACHE_TTL = 1.hour
    # Hidden gems are drawn at random from this many least-viewed photos
    HIDDEN_GEMS_POOL = 200

    def resolve(mode: nil, fetch_type: nil, limit: nil, offset: nil, page: nil, query: nil)
      if mode == 'paginated'
        paginated_photos(query, page)
      else
        simple_photos(fetch_type, limit, offset)
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
          base.where(hidden_from_feed: false).order(posted_at: :desc)
        end

      pagy, photos = context[:pagy].call(
        relation,
        page:
      )
      add_pagination_methods(photos, pagy)
      populate_feed_albums(photos) if query.blank?
      record_search(query:, results_count: pagy.count, page:)
      photos
    end

    def simple_photos(fetch_type, limit, offset)
      # Use Pundit policy scope for simple mode too
      base = Pundit.policy_scope(current_user, Photo.unscoped)

      photos =
        case fetch_type
        when 'random' then base.order('RANDOM()')
        # Same list as the paginated feed (collapsed albums stand in for their photos)
        when 'feed' then base.where(hidden_from_feed: false).order(posted_at: :desc)
        when 'on_this_day' then taken_on_this_day(base).order('RANDOM()')
        when 'this_month' then taken_this_month(base).order('RANDOM()')
        when 'trending' then trending(base)
        when 'most_viewed' then base.order(Arel.sql(TOTAL_VIEWS_SQL + ' DESC'), posted_at: :desc)
        when 'least_viewed' then hidden_gems(base)
        else base.order(posted_at: :desc)
        end

      photos = photos.offset([offset.to_i, 0].max).limit(effective_limit(limit))
      add_dummy_pagination_methods(photos)
      populate_feed_albums(photos) if fetch_type == 'feed'
      photos
    end

    # Photos with a real capture date (not the upload-date fallback of an
    # unknown source) taken on today's month and day in an earlier year.
    def taken_on_this_day(base)
      known_taken_dates(base, %w[day minute])
        .where('EXTRACT(YEAR FROM photos.taken_at) < ?', today.year)
        .where('EXTRACT(MONTH FROM photos.taken_at) = ? AND EXTRACT(DAY FROM photos.taken_at) = ?', today.month, today.day)
    end

    # Same month in any year, this one included. Today's date in earlier
    # years is left out so it never repeats the on-this-day list.
    def taken_this_month(base)
      known_taken_dates(base, %w[month day minute])
        .where('EXTRACT(MONTH FROM photos.taken_at) = ?', today.month)
        .where(<<~SQL.squish, today.year, today.day, 'month')
          NOT (EXTRACT(YEAR FROM photos.taken_at) < ?
               AND EXTRACT(DAY FROM photos.taken_at) = ?
               AND photos.taken_at_precision <> ?)
        SQL
    end

    def known_taken_dates(base, precisions)
      base.where(taken_at_approximate: false, taken_at_precision: precisions)
          .where.not(taken_at_source: 'unknown')
    end

    def today
      Time.zone.today
    end

    # Most viewed over the last week, by raw impressions. Impressions are
    # unfiltered by visibility, so the ids are cached once for everyone and
    # the caller's visibility scope is applied afterwards.
    def trending(base)
      ids = Rails.cache.fetch('homepage/trending_photo_ids/v1', expires_in: TRENDING_CACHE_TTL) do
        Impression.where(impressionable_type: 'Photo', created_at: TRENDING_WINDOW.ago..)
                  .group(:impressionable_id).order(Arel.sql('COUNT(*) DESC')).limit(TRENDING_POOL).count.keys
      end
      return base.none if ids.empty?

      position = "array_position(ARRAY[#{ids.map(&:to_i).join(',')}]::bigint[], photos.id::bigint)"
      base.where(id: ids).order(Arel.sql(position))
    end

    def hidden_gems(base)
      base.where(id: base.reorder(Arel.sql(TOTAL_VIEWS_SQL), :id).limit(HIDDEN_GEMS_POOL).select(:id))
          .order('RANDOM()')
    end

    # Determine the effective limit (apply MAX_LIMIT when not specified or when exceeding maximum)
    def effective_limit(limit)
      (limit || SIMPLE_MODE_MAX_LIMIT).clamp(0, SIMPLE_MODE_MAX_LIMIT)
    end
  end
end
