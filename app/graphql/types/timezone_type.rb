# frozen_string_literal: true

module Types
  # GraphQL Timezone Type
  class TimezoneType < Types::BaseObject
    description 'A timezone'
    field :name, String, 'Timezone name', null: false
  end
end
