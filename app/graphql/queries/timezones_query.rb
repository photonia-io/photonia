# frozen_string_literal: true

module Queries
  # Get the timezones
  class TimezonesQuery < BaseQuery
    type [Types::TimezoneType], null: false
    description 'Get the timezones'

    def resolve
      timezones = ActiveSupport::TimeZone::MAPPING.map do |name, key|
        { name:, key: }
      end
      timezones.sort_by { |timezone| timezone[:name] }
    end
  end
end
