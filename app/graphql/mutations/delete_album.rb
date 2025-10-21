# frozen_string_literal: true

module Mutations
  # Delete album mutation
  class DeleteAlbum < Mutations::BaseMutation
    description 'Delete album'

    argument :id, String, 'Album Id', required: true

    field :album, Types::AlbumType, null: true, description: 'The deleted album'
    field :errors, [String], null: false, description: 'List of errors encountered during the operation'

    def resolve(id:)
      album = find_album(id)
      return error_response('Album not found') unless album

      begin
        authorize(album, :destroy?)
      rescue Pundit::NotAuthorizedError
        return error_response('Not authorized to delete this album')
      end

      safely_destroy(album)
    end

    private

    def find_album(id)
      Album.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def safely_destroy(album)
      if album.destroy
        { album: album, errors: [] }
      else
        { album: nil, errors: album.errors.full_messages }
      end
    rescue StandardError => e
      { album: nil, errors: [e.message] }
    end

    def error_response(message)
      { album: nil, errors: [message] }
    end
  end
end
