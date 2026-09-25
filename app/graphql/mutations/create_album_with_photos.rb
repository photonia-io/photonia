# frozen_string_literal: true

module Mutations
  # Create album with photos
  class CreateAlbumWithPhotos < Mutations::BaseMutation
    description 'Create album with photos'

    argument :photo_ids, [String], 'Photo Ids', required: true
    argument :title, String, 'Album title', required: true

    type Types::AlbumType, null: false

    def resolve(title:, photo_ids:)
      album = Album.new(title: title, user: context[:current_user])
      authorize(album, :create?)

      photos_by_slug = Photo.unscoped.where(slug: photo_ids).index_by(&:slug)
      raise ActiveRecord::RecordNotFound if photos_by_slug.size != photo_ids.uniq.size

      photos = photo_ids.map { |id| photos_by_slug.fetch(id) }

      # Authorize every photo before creating anything, so a mid-loop
      # failure can't leave an orphaned or half-populated album behind.
      photos.each { |photo| authorize(photo, :update?) }

      ActiveRecord::Base.transaction do
        album.save!
        photos.each { |photo| album.photos << photo }
      end

      album.maintenance
    end
  end
end
