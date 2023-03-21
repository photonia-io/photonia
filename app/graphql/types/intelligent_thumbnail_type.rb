# frozen_string_literal: true

module Types
  # GraphQL Intelligent Thumbnail Type
  class IntelligentThumbnailType < Types::BaseObject
    description 'Intelligent thumbnail on a photo'

    field :bounding_box, BoundingBoxType, 'Bounding box of the intelligent thumbnail', null: false
    field :center_of_gravity, PointType, 'Center of gravity of the intelligent thumbnail', null: false

    def bounding_box
      {
        top: @object[:top],
        left: @object[:left],
        width: @object[:width],
        height: @object[:height]
      }
    end

    def center_of_gravity
      {
        top: @object[:center_of_gravity_top],
        left: @object[:center_of_gravity_left]
      }
    end
  end
end
