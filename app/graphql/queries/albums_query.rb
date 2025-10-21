# frozen_string_literal: true

module Queries
  # Get all albums
  class AlbumsQuery < BaseQuery
    type Types::AlbumType.collection_type, null: false
    description 'Find all albums by page'

    argument :page, Integer, 'Page number', required: false

    def resolve(page: nil)
      # Use Pundit policy scope to decide visibility:
      # - visitor: only public albums
      # - logged in: public albums + own albums (any privacy)
      # - admin: all albums
      base = Pundit.policy_scope(current_user, Album.unscoped)

      albums =
        if current_user&.admin?
          base
        elsif current_user
          # Show public albums that have public photos OR any of the user's albums regardless of public photo count
          base.where("(albums.privacy = 'public' AND albums.public_photos_count > 0) OR albums.user_id = ?", current_user.id)
        else
          # Visitors only see public albums with public photos
          base.where('albums.public_photos_count > 0')
        end

      pagy, records = context[:pagy].call(
        albums.includes(:public_cover_photo).order(created_at: :desc), page:
      )
      add_pagination_methods(records, pagy)
      records
    end
  end
end
