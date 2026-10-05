# frozen_string_literal: true

module Mutations
  # Regenerate an album's share link token, invalidating the previous link
  class RegenerateAlbumShareToken < Mutations::BaseMutation
    description "Regenerate an album's share link token, invalidating the previous link"

    argument :id, String, 'Album Id', required: true

    type Types::AlbumType, null: false

    def resolve(id:)
      album = find_album(id)
      authorize(album, :update?)

      album.regenerate_share_token!

      album
    end
  end
end
