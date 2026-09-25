# frozen_string_literal: true

module Mutations
  # Delete photos
  class DeletePhotos < Mutations::BaseMutation
    description 'Delete photos'

    argument :ids, [String], 'Photo Ids', required: true

    type [Types::PhotoType], null: false

    def resolve(ids:)
      photos_by_slug = Photo.unscoped.where(slug: ids).index_by(&:slug)
      raise ActiveRecord::RecordNotFound if photos_by_slug.size != ids.uniq.size

      photos = ids.map { |id| photos_by_slug.fetch(id) }

      # Authorize every photo before destroying any, so a mid-loop failure
      # can't leave some photos deleted and others not.
      photos.each { |photo| authorize(photo, :destroy?) }

      album_ids = AlbumsPhoto.where(photo_id: photos.map(&:id)).distinct.pluck(:album_id)

      ActiveRecord::Base.transaction do
        photos.each(&:destroy!)
      end

      Album.unscoped.where(id: album_ids).find_each(&:maintenance)

      photos
    end
  end
end
