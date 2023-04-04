# frozen_string_literal: true

class Photo
  # Tableless
  # Photo bounding box (a rectangle)
  class BoundingBox
    attr_reader :top, :left, :width, :height

    # accepts a hash (label instance['bounding_box'])
    def initialize(top:, left:, width:, height:)
      @top = top
      @left = left
      @width = width
      @height = height
    end
  end
end
