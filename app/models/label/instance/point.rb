# frozen_string_literal: true

module Label
  class Instance
    # Tableless
    # Label instance point
    class Point
      attr_accessor :top, :left

      def initialize(top, left)
        @top = top
        @left = left
      end
    end
  end
end
