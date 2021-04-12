# frozen_string_literal: true

module CoreExtensions
  module Hash
    # Hash sanitizer monkey patch
    module Sanitizer
      def sanitize_invalid_byte_sequence!
        each do |key, value|
          case value
          when ::Hash
            self[key] = value.sanitize_invalid_byte_sequence!
          when String
            self[key] = value.delete("\000").encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
          end
        end
      end
    end
  end
end
