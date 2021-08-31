# frozen_string_literal: true

class Photo
  # Tableless
  # A point inside a Photo
  class Point
    attr_accessor :top, :left

    def initialize(top, left)
      @top = top
      @left = left
    end
  end
end
