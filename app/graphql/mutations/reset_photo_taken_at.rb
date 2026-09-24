# frozen_string_literal: true

module Mutations
  # Reset photo taken_at back to its EXIF/upload-derived value
  class ResetPhotoTakenAt < Mutations::BaseMutation
    description 'Reset photo date taken to the EXIF or upload date'

    argument :id, String, 'Photo Id', required: true

    type Types::PhotoType, null: false

    def resolve(id:)
      photo = find_photo(id)
      raise GraphQL::ExecutionError, 'Photo not found' unless photo

      authorize(photo, :update?)

      photo.reset_taken_at

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
