# frozen_string_literal: true

module Types
  # GraphQL Intelligent Thumbnail Type
  class IntelligentThumbnailType < Types::BaseObject
    description 'An intelligent thumbnail'

    field :bounding_box, BoundingBoxType, null: false
    field :center_of_gravity_left, Float, null: false
    field :center_of_gravity_top, Float, null: false

    def bounding_box
      {
        top: @object[:top],
        left: @object[:left],
        width: @object[:width],
        height: @object[:height]
      }
    end
  end
end
