# frozen_string_literal: true

module Types
  # GraphQL Bounding Box Type
  class BoundingBoxType < Types::BaseObject
    description 'A bounding box'

    field :top, Float, null: false
    field :left, Float, null: false
    field :width, Float, null: false
    field :height, Float, null: false
  end
end
