# frozen_string_literal: true

module Types
  # GraphQL Input for User Thumbnail
  class UserThumbnailInput < Types::BaseInputObject
    description 'Input for user-defined thumbnail bounding box'

    argument :top, Float, 'Percent of image where the top side of the bounding box is', required: true
    argument :left, Float, 'Percent of image where the left side of the bounding box is', required: true
    argument :width, Float, 'Width of the bounding box in percents of image width', required: true
    argument :height, Float, 'Height of the bounding box in percents of image height', required: true
  end
end
