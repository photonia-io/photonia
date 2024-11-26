# frozen_string_literal: true

module Queries
  class PhotoQuery < BaseQuery
    type Types::PhotoType, null: false
    description 'Find a photo by ID'

    argument :id, ID, 'ID of the photo', required: true

    def resolve(id:)
      photo = Photo.includes(:albums, :albums_photos, :comments).friendly.find(id)
      record_impression(photo)
      photo
    end
  end
end
