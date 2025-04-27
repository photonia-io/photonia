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
      photo_query = Photo
      photo_query = photo_query.includes(:albums, :albums_photos) if lookahead.selects?(:albums)
      photo_query = photo_query.includes(comments: %i[flickr_user versions]) if lookahead.selects?(:comments)
      photo = if fetch_type == 'latest'
                photo_query.order(posted_at: :desc).first
              else
                photo_query.friendly.find(id)
              end
      record_impression(photo)
      photo
    end
  end
end
