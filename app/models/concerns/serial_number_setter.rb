# frozen_string_literal: true

module SerialNumberSetter
  extend ActiveSupport::Concern

  included do
    private

    def maximum_serial_number
      self.class.unscoped.maximum('serial_number') || 1_000_000_000
    end

    def set_serial_number
      self.serial_number = maximum_serial_number + rand(1..10_000_000)
    end
  end
end
