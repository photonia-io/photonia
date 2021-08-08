# frozen_string_literal: true

module Label
  class Instance
    # Tableless
    # Label instance bounding box
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
end
