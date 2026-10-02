# frozen_string_literal: true

module Types
  # An album with its view count on a given day
  class ViewedAlbumType < Types::BaseObject
    description 'An album and how many times it was viewed'

    field :album, AlbumType, 'The viewed album', null: false
    field :count, Integer, 'Number of views', null: false
  end
end
