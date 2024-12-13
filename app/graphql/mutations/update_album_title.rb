# frozen_string_literal: true

module Mutations
  # Update album title
  class UpdateAlbumTitle < Mutations::BaseMutation
    description 'Update album title'

    argument :id, String, 'Photo Id', required: true
    argument :title, String, 'New album title', required: true

    type Types::AlbumType, null: false

    def resolve(id:, title:)
      album = Album.friendly.find(id)
      context[:authorize].call(album, :update?)
      raise GraphQL::ExecutionError, album.errors.full_messages.join(', ') unless album.update(title: title)

      album
    end
  end
end
