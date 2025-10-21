# frozen_string_literal: true

module Mutations
  # Add photos to album
  class AddPhotosToAlbum < Mutations::BaseMutation
    description 'Add photos to album'

    argument :album_id, String, 'Album Id', required: true
    argument :photo_ids, [String], 'Photo Ids', required: true

    type Types::AlbumType, null: false

    def resolve(album_id:, photo_ids:)
      base = Pundit.policy_scope(context[:current_user], Album.unscoped)
      album = base.includes(:photos).friendly.find(album_id)
      context[:authorize].call(album, :update?)

      photo_ids.each do |photo_id|
        photo = Photo.friendly.find(photo_id)
        context[:authorize].call(photo, :update?)
        # only add photo if it's not already in the album
        album.photos << photo unless album.photos.include?(photo)
      end

      album.maintenance
    end
  end
end
