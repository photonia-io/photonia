# frozen_string_literal: true

module Queries
  # Get all albums
  class AlbumsQuery < BaseQuery
    type Types::AlbumType.collection_type, null: false
    description 'Find all albums by page'

    argument :page, Integer, 'Page number', required: false

    def resolve(page: nil)
      pagy, albums = context[:pagy].call(
        Album.includes(:public_cover_photo).where('public_photos_count > ?', 0).order(created_at: :desc), page:
      )
      add_pagination_methods(albums, pagy)
      albums
    end
  end
end
