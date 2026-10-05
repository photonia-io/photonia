# frozen_string_literal: true

module Queries
  # Photo Query
  class PhotoQuery < BaseQuery
    type Types::PhotoType, null: false
    description 'Find a photo by ID or fetch the latest photo'

    extras [:lookahead]

    argument :fetch_type, String, 'Type of fetch operation (e.g. "by_id", "latest")', default_value: 'by_id', required: false
    argument :id, ID, 'ID of the photo', required: false, default_value: nil
    argument :in_album, ID, 'Album slug for a share link that may cover this photo', required: false, default_value: nil
    argument :share, String, 'Share token for the album given in in_album', required: false, default_value: nil

    def resolve(lookahead:, fetch_type:, id:, in_album:, share:)
      # Resolved and stored in context up front - even a public photo found
      # through the normal scope needs it, so PhotoType#albums can still
      # surface a private album this share link covers.
      access = AlbumShareAccess.resolve(in_album, share)
      context[:album_share] = access if access

      photo = locate_photo(fetch_type:, id:, access:, lookahead:)
      raise GraphQL::ExecutionError, 'Photo not found' unless photo

      authorize(photo, :show?) unless access&.covers_photo?(photo)
      record_impression(photo)
      photo
    end

    private

    def locate_photo(fetch_type:, id:, access:, lookahead:)
      # Use Pundit policy scope to decide visibility:
      # - visitor: only public photos
      # - logged in: public photos + own photos (any privacy)
      # - admin: all photos
      photo_query = with_comments(Pundit.policy_scope(current_user, Photo.unscoped), lookahead)

      if fetch_type == 'latest'
        photo = photo_query.where(hidden_from_feed: false).order(posted_at: :desc).first
        # Only the homepage's "latest" spotlight is feed-like; a direct
        # by_id lookup (the photo page) never gets a feed_album, even for
        # this same photo.
        populate_feed_albums([photo]) if photo
        return photo
      end

      find_by_id_or_share(photo_query, id:, access:, lookahead:)
    end

    def find_by_id_or_share(photo_query, id:, access:, lookahead:)
      photo_query.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      raise unless access

      with_comments(access.photo_scope, lookahead).find_by(slug: id)
    end
  end
end
