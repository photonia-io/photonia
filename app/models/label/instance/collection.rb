# frozen_string_literal: true

module Label
  class Instance
    # Tableless
    # Rekognition label instance collection
    class Collection
      attr_reader :label_instances
      attr_writer :mode

      def initialize
        @label_instances = []
        @mode = :person
      end

      def add(label, instances)
        instances.each do |instance|
          @label_instances << Label::Instance.new(label, instance)
        end
      end

      def sort_by_confidence
        @label_instances.sort_by(&:confidence).reverse
      end

      def person_present?
        @label_instances.each do |instance|
          return true if instance.person?
        end
        false
      end

      def center_of_gravity
        {
          top: average(:top),
          left: average(:left)
        }
      end

      private

      def filtered_label_instances
        person_present? ? @label_instances.select(&:person?) : @label_instances
      end

      def average(type)
        total = 0
        area_total = 0
        filtered_label_instances.each do |instance|
          total += instance.center.send(type) * instance.area
          area_total += instance.area
        end
        total / area_total
      end
    end
  end
end
