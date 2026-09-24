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
      raise GraphQL::ExecutionError, 'Photo not found' unless photo

      authorize(photo, :update?)

      mapped = map_privacy_value(privacy)
      raise GraphQL::ExecutionError, 'Invalid privacy value' unless mapped

      raise GraphQL::ExecutionError, photo.errors.full_messages.join(', ') unless photo.update(privacy: mapped)

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

    # Accepts:
    # - "public"
    # - "private"
    # - "friends_and_family" (maps to DB enum value "friend & family")
    def map_privacy_value(value)
      case value.to_s
      when 'public' then 'public'
      when 'private' then 'private'
      when 'friends_and_family' then 'friend & family'
      else
        nil
      end
    end
  end
end
