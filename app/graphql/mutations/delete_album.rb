# frozen_string_literal: true

module Mutations
  # Delete album mutation
  class DeleteAlbum < Mutations::BaseMutation
    description 'Delete album'

    argument :id, String, 'Album Id', required: true

    type Types::AlbumType, null: false

    def resolve(id:)
      album = Album.friendly.find(id)
      authorize(album, :destroy?)
      album.destroy
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, 'Album not found'
    end
  end
end
