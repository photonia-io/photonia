# frozen_string_literal: true

module Queries
  # Photo Query
  class PhotoQuery < BaseQuery
    type Types::PhotoType, null: false
    description 'Find a photo by ID or fetch the latest photo'

    extras [:lookahead]

    argument :fetch_type, String, 'Type of fetch operation (e.g. "by_id", "latest")', default_value: 'by_id', required: false
    argument :id, ID, 'ID of the photo', required: false, default_value: nil

    def resolve(lookahead:, fetch_type:, id:)
      # Use Pundit policy scope to decide visibility:
      # - visitor: only public photos
      # - logged in: public photos + own photos (any privacy)
      # - admin: all photos
      base = Pundit.policy_scope(current_user, Photo.unscoped)

      photo_query = base
      photo_query = photo_query.includes(:albums, :albums_photos) if lookahead.selects?(:albums)
      photo_query = photo_query.includes(comments: %i[flickr_user versions]) if lookahead.selects?(:comments)

      photo =
        if fetch_type == 'latest'
          photo_query.order(posted_at: :desc).first
        else
          photo_query.friendly.find(id)
        end

      authorize(photo, :show?)
      record_impression(photo)
      photo
    end
  end
end
