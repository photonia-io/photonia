# frozen_string_literal: true

module Types
  # GraphQL Image Dimensions Type
  class ImageDimensionsType < Types::BaseObject
    description 'Pixel dimensions of a specific image derivative'

    field :height, Integer, 'Height in pixels', null: false
    field :width, Integer, 'Width in pixels', null: false
  end
end
