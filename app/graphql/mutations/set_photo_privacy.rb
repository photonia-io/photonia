# frozen_string_literal: true

module Mutations
  # Set photo privacy
  class SetPhotoPrivacy < Mutations::BaseMutation
    description 'Set photo privacy'

    argument :id, String, 'Photo Id', required: true
    argument :privacy, String, 'Photo privacy (public, private, friends_and_family)', required: true

    type Types::PhotoType, null: false

    def resolve(id:, privacy:)
      photo = find_photo(id)

      authorize(photo, :update?)

      raise GraphQL::ExecutionError, 'Invalid privacy value' unless Photo.privacies.key?(privacy)

      raise GraphQL::ExecutionError, photo.errors.full_messages.join(', ') unless photo.update(privacy:)

      Album.maintain_containing([photo.id]) if photo.saved_change_to_privacy?

      photo
    end

    private

    def find_photo(id)
      # Use policy scope to bypass default scope while respecting visibility for the current user
      Pundit.policy_scope(context[:current_user], Photo.unscoped).friendly.find(id)
    end
  end
end
