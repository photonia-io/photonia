# frozen_string_literal: true

module Mutations
  # Create an album share/invite
  class CreateAlbumShare < Mutations::BaseMutation
    description 'Share an album with a user by email'

    argument :album_id, String, 'Album ID (slug)', required: true
    argument :email, String, 'Email address to share with', required: true

    type Types::AlbumShareType, null: false

    def resolve(album_id:, email:)
      album = find_album(album_id)
      raise GraphQL::ExecutionError, 'Album not found' unless album

      # Only the album owner can share it
      authorize(album, :update?)

      # Create the share
      share = album.album_shares.build(
        email:,
        shared_by_user_id: context[:current_user].id
      )

      unless share.save
        error_message = share.errors.full_messages.join(', ')
        raise GraphQL::ExecutionError, error_message
      end

      share
    end

    private

    def find_album(id)
      # Use policy scope to bypass default scope while respecting visibility for the current user
      base = Pundit.policy_scope(context[:current_user], Album.unscoped)
      base.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
