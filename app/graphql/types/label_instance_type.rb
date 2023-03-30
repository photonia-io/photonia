# frozen_string_literal: true

module Types
  # GraphQL Label Instance Type
  class LabelInstanceType < Types::BaseObject
    description 'A label instance'

    field :bounding_box, BoundingBoxType, 'Bounding box of the label instance', null: false
    field :confidence, Float, 'Confidence of the label instance', null: false
    field :id, String, 'ID of the label instance', null: false
    field :name, String, 'Name of the label instance', null: false
  end
end
