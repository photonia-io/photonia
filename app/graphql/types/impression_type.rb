# frozen_string_literal: true

module Types
  # GraphQL Impression Type
  class ImpressionType < Types::BaseObject
    description 'Impression count for a date'

    field :count, Integer, 'Impression count', null: false
    field :date, String, 'Date of the impression count', null: false
  end
end
