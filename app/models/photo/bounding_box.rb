# frozen_string_literal: true

class Photo
  # Tableless
  # Photo bounding box (a rectangle)
  class BoundingBox
    attr_reader :top, :left, :width, :height

    # accepts a hash (label instance['bounding_box'])
    def initialize(bounding_box)
      @top = bounding_box['top']
      @left = bounding_box['left']
      @width = bounding_box['width']
      @height = bounding_box['height']
    end
  end
end
