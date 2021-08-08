# frozen_string_literal: true

module Label
  # Tableless
  # Rekognition label instance
  class Instance
    attr_reader :name, :confidence, :bounding_box

    def initialize(label, instance)
      @name = label['name']
      @confidence = instance['confidence']
      @bounding_box = Label::Instance::BoundingBox.new(instance['bounding_box'])
    end

    def center
      Label::Instance::Point.new(
        @bounding_box.top + @bounding_box.height / 2,
        @bounding_box.left + @bounding_box.width / 2
      )
    end

    def area
      100 * (@bounding_box.top + @bounding_box.height) * (@bounding_box.left + @bounding_box.width)
    end

    def person?
      name == 'Person'
    end
  end
end
