# frozen_string_literal: true

module Mutations
  # Update album description
  class UpdateAlbumDescription < Mutations::BaseMutation
    description 'Update album description'

    argument :description, String, 'New album description', required: true
    argument :id, String, 'Photo Id', required: true

    type Types::AlbumType, null: false

    def resolve(id:, description:)
      begin
        album = Album.friendly.find(id)
      rescue ActiveRecord::RecordNotFound
        raise GraphQL::ExecutionError, 'Album not found'
      end
      authorize(album, :update?)
      raise GraphQL::ExecutionError, album.errors.full_messages.join(', ') unless album.update(description: description)

      album
    end
  end
end
