# frozen_string_literal: true

module Mutations
  # Set photo taken_at
  class SetPhotoTakenAt < Mutations::BaseMutation
    description 'Set photo date taken'

    argument :approximate, Boolean, 'Whether the date is approximate', required: false, default_value: false
    argument :day, Integer, 'Day of month, omit if unknown', required: false
    argument :hour, Integer, 'Hour of day, omit if unknown', required: false
    argument :id, String, 'Photo Id', required: true
    argument :minute, Integer, 'Minute of hour, omit if unknown', required: false
    argument :month, Integer, 'Month, omit if unknown', required: false
    argument :scanned, Boolean, 'Whether the photo is a scan of a print or negative', required: false, default_value: false
    argument :year, Integer, 'Year', required: true

    type Types::PhotoType, null: false

    def resolve(id:, year:, month: nil, day: nil, hour: nil, minute: nil, approximate: false, scanned: false)
      photo = find_photo(id)
      raise GraphQL::ExecutionError, 'Photo not found' unless photo

      authorize(photo, :update?)

      raise GraphQL::ExecutionError, photo.errors.full_messages.join(', ') unless photo.assign_taken_at(year:, month:, day:, hour:, minute:, approximate:, scanned:)

      raise GraphQL::ExecutionError, photo.errors.full_messages.join(', ') unless photo.save

      photo
    end

    private

    def find_photo(id)
      # Use policy scope to bypass default scope while respecting visibility for the current user
      base = Pundit.policy_scope(context[:current_user], Photo.unscoped)
      base.friendly.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
