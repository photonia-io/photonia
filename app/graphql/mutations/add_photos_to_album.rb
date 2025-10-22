# frozen_string_literal: true

module Mutations
  # Add photos to album
  class AddPhotosToAlbum < Mutations::BaseMutation
    description 'Add photos to album'

    argument :album_id, String, 'Album Id', required: true
    argument :photo_ids, [String], 'Photo Ids', required: true

    field :album, Types::AlbumType, null: true, description: 'The updated album'
    field :errors, [String], null: false, description: 'List of errors encountered during the operation'

    def resolve(album_id:, photo_ids:)
      album = find_album(album_id)
      return error_response('Album not found') unless album

      begin
        authorize(album, :update?)
      rescue Pundit::NotAuthorizedError
        return error_response('Not authorized to update this album')
      end

      photos = Photo.unscoped.where(slug: photo_ids)
      return error_response('One or more photos not found') if photos.size != photo_ids.uniq.size

      # Ensure user can edit all photos before making any changes
      photos.each do |photo|
        authorize(photo, :update?)
      rescue Pundit::NotAuthorizedError
        return error_response('Not authorized to update this photo')
      end

      ActiveRecord::Base.transaction do
        existing_photo_ids = album.photos.pluck(:id).to_set
        photos.each do |photo|
          album.photos << photo unless existing_photo_ids.include?(photo.id)
        end
      end

      album.maintenance

      { album: album, errors: [] }
    rescue StandardError => e
      error_response(e.message)
    end

    private

    def find_album(id)
      base = Pundit.policy_scope(context[:current_user], Album.unscoped)
      base.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def error_response(message)
      { album: nil, errors: [message] }
    end
  end
end
