# frozen_string_literal: true

module Types
  # GraphQL Taken At Info Type
  class TakenAtInfoType < Types::BaseObject
    description 'Precision-aware breakdown of a photo taken_at'

    field :approximate, Boolean, 'Whether the date is approximate', null: false
    field :day, Integer, 'Day of month, null if not known', null: true
    field :exif_available, Boolean, 'Whether an EXIF capture date is available to reset to', null: false
    field :hour, Integer, 'Hour of day, null if not known', null: true
    field :minute, Integer, 'Minute of hour, null if not known', null: true
    field :month, Integer, 'Month, null if not known', null: true
    field :precision, String, 'How much of the date is known (year, month, day, minute)', null: false
    field :source, String, 'Where the date came from (exif, user, unknown)', null: false
    field :year, Integer, 'Year', null: true
  end
end
