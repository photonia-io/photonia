# frozen_string_literal: true

module Types
  # GraphQL Label Instance Type
  class LabelType < Types::BaseObject
    description 'A label'

    field :bounding_box, BoundingBoxType, 'Bounding box of the label instance', null: false
    field :confidence, Float, 'Confidence of the label instance', null: false
    field :id, String, 'ID of the label instance', null: false
    field :name, String, 'Name of the label instance', null: false
    field :sequenced_name, String, 'Sequenced name of the label instance', null: true
  end
end
