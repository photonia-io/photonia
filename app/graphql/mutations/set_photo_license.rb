# frozen_string_literal: true

module Mutations
  # Set photo license
  class SetPhotoLicense < Mutations::BaseMutation
    description 'Set photo license'

    argument :id, String, 'Photo Id', required: true
    argument :license, String, 'New photo license', required: false

    type Types::PhotoType, null: false

    def resolve(id:, license: nil)
      photo = find_photo(id)
      raise GraphQL::ExecutionError, 'Photo not found' unless photo

      authorize(photo, :update?)

      normalized = license.presence
      raise GraphQL::ExecutionError, 'Invalid license value' if normalized && License::VALUES.exclude?(normalized)

      raise GraphQL::ExecutionError, photo.errors.full_messages.join(', ') unless photo.update(license: normalized)

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
