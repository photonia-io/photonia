# frozen_string_literal: true

module Queries
  # Photo Query
  class PhotoQuery < BaseQuery
    type Types::PhotoType, null: false
    description 'Find a photo by ID or fetch the latest photo'

    argument :fetch_type, String, 'Type of fetch operation (e.g. "by_id", "latest")', default_value: 'by_id', required: false
    argument :id, ID, 'ID of the photo', required: false, default_value: nil

    def resolve(fetch_type:, id:)
      photo = Photo.includes(:albums, :albums_photos, comments: %i[flickr_user versions])
      photo = if fetch_type == 'latest'
                photo.order(posted_at: :desc).first
              else
                photo.friendly.find(id)
              end
      record_impression(photo)
      photo
    end
  end
end
