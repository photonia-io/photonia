# frozen_string_literal: true

# Tableless
# Rekognition label instance collection
class LabelInstanceCollection
  attr_reader :label_instances

  def initialize
    @label_instances = []
  end

  def add(label, instances)
    instances.each do |instance|
      @label_instances << LabelInstance.new(label, instance)
    end
  end

  def sorted_by_confidence
    @label_instances.sort_by(&:confidence).reverse
  end
end
