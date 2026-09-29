# frozen_string_literal: true

module Queries
  # Get all albums, or a simple unpaginated list for pickers (#1101:
  # currentUser.albums is uploader-only, but the advanced search's album
  # filter and #710's above-the-grid album matches need it for any visitor)
  class AlbumsQuery < BaseQuery
    type Types::AlbumType.collection_type, null: false
    description 'Find all albums by page, or a simple filtered list'

    argument :mode, String, 'Mode of operation ("paginated" or "simple")', required: false, default_value: 'paginated'

    # Paginated mode arguments
    argument :page, Integer, 'Page number. Applies to the paginated mode.', required: false

    # Simple mode arguments
    argument :query, String, 'Filter by title (prefix match). Applies to the simple mode.', required: false
    argument :limit, Integer, 'Max number of results. Applies to the simple mode.', required: false

    SIMPLE_MODE_MAX_LIMIT = 100

    def resolve(mode: 'paginated', page: nil, query: nil, limit: nil)
      if mode == 'paginated'
        paginated_albums(page)
      else
        simple_albums(query, limit)
      end
    end

    private

    # Use Pundit policy scope to decide visibility:
    # - visitor: only public albums
    # - logged in: public albums + own albums (any privacy)
    # - admin: all albums
    def visible_albums
      base = Pundit.policy_scope(current_user, Album.unscoped)

      if current_user&.admin?
        base
      elsif current_user
        # Show public albums that have public photos OR any of the user's albums regardless of public photo count
        base.where("(albums.privacy = 'public' AND albums.public_photos_count > 0) OR albums.user_id = ?", current_user.id)
      else
        # Visitors only see public albums with public photos
        base.where('albums.public_photos_count > 0')
      end
    end

    def paginated_albums(page)
      pagy, records = context[:pagy].call(
        visible_albums.includes(:public_cover_photo).order(created_at: :desc), page:
      )
      add_pagination_methods(records, pagy)
      records
    end

    def simple_albums(query, limit)
      albums = visible_albums
      albums = albums.where('title ILIKE ?', "#{sanitize_like(query)}%") if query.present?
      albums = albums.order(:title).limit(effective_limit(limit))
      add_dummy_pagination_methods(albums)
      albums
    end

    def effective_limit(limit)
      (limit || SIMPLE_MODE_MAX_LIMIT).clamp(0, SIMPLE_MODE_MAX_LIMIT)
    end
  end
end
