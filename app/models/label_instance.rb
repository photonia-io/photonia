# frozen_string_literal: true

# Tableless
# Rekognition label instance
class LabelInstance
  attr_reader :name, :confidence, :bounding_box

  def initialize(label, instance)
    @name = label['name']
    @confidence = instance['confidence']
    @bounding_box = instance['bounding_box']
  end

  def center_of_gravity
    {
      top: @bounding_box['top'] + @bounding_box['height'] / 2,
      left: @bounding_box['left'] + @bounding_box['width'] / 2
    }
  end
end
