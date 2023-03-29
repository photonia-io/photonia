# frozen_string_literal: true

module Label
  # Tableless
  # Rekognition label instance
  class Instance
    attr_reader :id, :name, :confidence, :bounding_box
    attr_accessor :sequenced_name

    def initialize(label, instance)
      @name = label['name']
      @confidence = instance['confidence']
      @bounding_box = Photo::BoundingBox.new(instance['bounding_box'])
    end

    def center
      Photo::Point.new(
        @bounding_box.top + (@bounding_box.height / 2),
        @bounding_box.left + (@bounding_box.width / 2)
      )
    end

    def area
      100 * (@bounding_box.top + @bounding_box.height) * (@bounding_box.left + @bounding_box.width)
    end

    def person?
      name == 'Person'
    end

    def id
      @id ||= Digest::MD5.hexdigest("#{name} #{confidence} #{bounding_box.top} #{bounding_box.left} #{bounding_box.width} #{bounding_box.height}")
    end
  end
end
