# frozen_string_literal: true

module Types
  # GraphQL Label Instance Type
  class LabelInstanceType < Types::BaseObject
    description 'A label instance'

    field :bounding_box, BoundingBoxType, null: false
    field :confidence, Float, null: false
    field :id, String, null: false
    field :name, String, null: false
  end
end
