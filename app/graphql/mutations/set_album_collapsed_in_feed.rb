# frozen_string_literal: true

module Mutations
  # Collapse or uncollapse an album on the photo feed (see #907): a
  # collapsed album shows as a single entry (its cover) in the feed, and its
  # other photos are hidden from it.
  class SetAlbumCollapsedInFeed < Mutations::BaseMutation
    description 'Set whether an album collapses to a single entry on the photo feed'

    argument :collapsed, Boolean, 'Whether the album should collapse on the feed', required: true
    argument :id, String, 'Album Id', required: true

    field :album, Types::AlbumType, 'The updated album', null: false

    def resolve(id:, collapsed:)
      album = find_album(id)

      authorize(album, :update?)

      if collapsed && (blocker = album.collapse_blocker)
        raise GraphQL::ExecutionError, blocker
      end

      raise GraphQL::ExecutionError, album.errors.full_messages.join(', ') unless album.update(collapsed_in_feed: collapsed)

      { album: }
    end
  end
end
