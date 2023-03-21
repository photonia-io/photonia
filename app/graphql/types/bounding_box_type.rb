# frozen_string_literal: true

module Types
  # GraphQL Bounding Box Type
  class BoundingBoxType < Types::BaseObject
    description 'Bounding box on a photo'

    field :height, Float, 'Height of the bounding box in percents of image height', null: false
    field :left, Float, 'Percent of image where the left side of the bounding box is', null: false
    field :top, Float, 'Percent of image where the top side of the bounding box is', null: false
    field :width, Float, 'Width of the bounding box in percents of image width', null: false
  end
end
