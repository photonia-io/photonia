# frozen_string_literal: true

module Mutations
  # Set an album's share link mode
  class SetAlbumShareMode < Mutations::BaseMutation
    description "Set an album share link's mode"

    argument :id, String, 'Album Id', required: true
    argument :mode, String, 'Share mode (off, public_photos, all_photos)', required: true

    type Types::AlbumType, null: false

    def resolve(id:, mode:)
      album = find_album(id)
      authorize(album, :update?)

      raise GraphQL::ExecutionError, 'Invalid share mode' unless Album.share_modes.key?(mode)

      # The token is created lazily, the first time sharing is turned on, and
      # never changes just from switching modes - only Regenerate does that.
      album.regenerate_share_token! if mode != 'off' && album.share_token.blank?
      # rubocop:disable Rails/SkipsModelValidations
      album.update_columns(share_mode: mode)
      # rubocop:enable Rails/SkipsModelValidations

      album
    end
  end
end
