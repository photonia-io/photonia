# frozen_string_literal: true

module Mutations
  # Set album cover photo mutation
  #
  # This mutation:
  # - checks that the current user can edit the album
  # - ensures the photo belongs to the current user
  # - ensures the photo is part of the album
  # - sets only the user_cover_photo_id and then triggers Album#maintenance
  class SetAlbumCoverPhoto < Mutations::BaseMutation
    description 'Set album cover photo'

    argument :album_id, String, 'Album Id', required: true
    argument :photo_id, String, 'Photo Id', required: true

    field :album, Types::AlbumType, null: true, description: 'The updated album'
    field :errors, [String], null: false, description: 'List of errors encountered during the operation'

    def resolve(album_id:, photo_id:)
      album = find_album(album_id)
      return error_response('Album not found') unless album

      # Authorization: can the user edit the album?
      begin
        authorize(album, :update?)
      rescue Pundit::NotAuthorizedError
        return error_response('Not authorized to update this album')
      end

      user = context[:current_user]
      return error_response('User not signed in') unless user

      photo = find_photo(photo_id)
      return error_response('Photo not found') unless photo

      # does the photo belong to the user?
      return error_response('Photo does not belong to user') unless photo.user_id == user.id

      # does the photo belong to the album? (unscoped-safe via join)
      return error_response('Photo not found in album') unless AlbumsPhoto.exists?(album_id: album.id, photo_id: photo.id)

      # Only set user_cover_photo_id; callbacks will trigger Album#maintenance
      album.update!(user_cover_photo_id: photo.id)

      { album: album, errors: [] }
    rescue StandardError => e
      error_response(e.message)
    end

    private

    def find_album(id)
      Album.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def find_photo(id)
      # Unscoped to allow private photos owned by the user to be set as cover
      Photo.unscoped.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def error_response(message)
      { album: nil, errors: [message] }
    end
  end
end
