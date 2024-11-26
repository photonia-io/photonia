# frozen_string_literal: true

module Queries
  # Get an album by ID
  class AlbumQuery < BaseQuery
    type Types::AlbumType, null: false
    description 'Find an album by ID'

    argument :id, ID, 'ID of the album', required: true

    def resolve(id:)
      album = Album.includes(:albums_photos).friendly.find(id)
      record_impression(album)
      album
    end
  end
end
