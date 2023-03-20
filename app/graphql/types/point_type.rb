# frozen_string_literal: true

module Types
  # GraphQL Point Type
  class PointType < Types::BaseObject
    description 'Shows a point on a photo'

    field :left, Float, 'Percent of image width where the point is', null: false
    field :top, Float, 'Percent of image height where the point is', null: false
  end
end
