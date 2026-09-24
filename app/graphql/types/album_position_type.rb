# frozen_string_literal: true

module Types
  # GraphQL Album Position Type
  class AlbumPositionType < Types::BaseObject
    description "A photo's position within an album"

    field :page, Integer, 'Page of the album grid the photo falls on', null: false
    field :position, Integer, 'One-based position of the photo in the album', null: false
    field :total, Integer, 'Number of photos in the album visible to the current user', null: false
  end
end
