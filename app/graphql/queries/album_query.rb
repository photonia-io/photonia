# frozen_string_literal: true

module Queries
  # Get an album by ID
  class AlbumQuery < BaseQuery
    type Types::AlbumType, null: true
    description 'Find an album by ID'

    extras [:lookahead]

    argument :id, ID, 'ID of the album', required: true

    def resolve(lookahead:, id:)
      base = Pundit.policy_scope(current_user, Album.unscoped)
      album = with_comments(base, lookahead).friendly.find(id)
      authorize(album, :show?)
      record_impression(album)
      album
    end
  end
end
