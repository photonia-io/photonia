# frozen_string_literal: true

module Queries
  # Get an album by ID
  class AlbumQuery < BaseQuery
    type Types::AlbumType, null: true
    description 'Find an album by ID'

    extras [:lookahead]

    argument :id, ID, 'ID of the album', required: true
    argument :share, String, 'Share token unlocking a non-public album', required: false, default_value: nil

    def resolve(lookahead:, id:, share:)
      album = find_by_id_or_share(id:, share:, lookahead:)
      raise ActiveRecord::RecordNotFound unless album

      authorize(album, :show?)
      record_impression(album)
      album
    end

    private

    def find_by_id_or_share(id:, share:, lookahead:)
      with_comments(Pundit.policy_scope(current_user, Album.unscoped), lookahead).friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      access = AlbumShareAccess.resolve(id, share)
      return nil unless access

      context[:album_share] = access
      with_comments(Album.unscoped, lookahead).find(access.album.id)
    end
  end
end
