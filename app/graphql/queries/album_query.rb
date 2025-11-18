# frozen_string_literal: true

module Queries
  # Get an album by ID
  class AlbumQuery < BaseQuery
    type Types::AlbumType, null: true
    description 'Find an album by ID'

    argument :id, ID, 'ID of the album', required: true

    def resolve(id:)
      # First try to find the album without scoping (to support visitor tokens)
      album = Album.unscoped.friendly.find(id)

      # Check if the user has access via visitor token
      if has_visitor_token_access?(album)
        record_impression(album)
        return album
      end

      # Otherwise, use normal authorization
      authorize(album, :show?)

      # Additional check: if album is private, verify user has access via share or ownership
      if album.private_privacy? || album.friends_and_family_privacy?
        unless can_access_album?(album)
          raise Pundit::NotAuthorizedError
        end
      end

      record_impression(album)
      album
    end

    private

    def has_visitor_token_access?(album)
      token = context[:visitor_token]
      return false unless token

      AlbumShare.exists?(album_id: album.id, visitor_token: token)
    end

    def can_access_album?(album)
      # Owner can always access
      return true if current_user && album.user_id == current_user.id

      # Admin can always access
      return true if current_user&.admin?

      # Check if album is shared with the user
      return true if current_user && AlbumShare.exists?(album_id: album.id, user_id: current_user.id)

      false
    end
  end
end
