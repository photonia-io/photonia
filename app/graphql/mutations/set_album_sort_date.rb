# frozen_string_literal: true

module Mutations
  # Set or clear the date that stands in for created_at in album list order
  class SetAlbumSortDate < Mutations::BaseMutation
    description "Set or clear an album's list sort date"

    argument :id, String, 'Album Id', required: true
    argument :sort_date, GraphQL::Types::ISO8601Date, 'Sort date, or null to fall back to the creation date', required: false

    type Types::AlbumType, null: false

    def resolve(id:, sort_date: nil)
      album = find_album(id)
      authorize(album, :update?)

      # rubocop:disable Rails/SkipsModelValidations
      album.update_columns(sort_date:)
      # rubocop:enable Rails/SkipsModelValidations

      album
    end
  end
end
