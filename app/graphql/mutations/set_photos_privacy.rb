# frozen_string_literal: true

module Mutations
  # Set privacy for multiple photos at once
  class SetPhotosPrivacy < Mutations::BaseMutation
    description 'Set privacy for multiple photos'

    argument :photo_ids, [String], 'Array of Photo IDs', required: true
    argument :privacy, String, 'Photo privacy (public, private, friends_and_family)', required: true

    field :photos, [Types::PhotoType], null: false
    field :errors, [String], null: false

    def resolve(photo_ids:, privacy:)
      mapped_privacy = map_privacy_value(privacy)
      raise GraphQL::ExecutionError, 'Invalid privacy value' unless mapped_privacy

      photos = find_photos(photo_ids)
      errors = []

      photos.each do |photo|
        begin
          authorize(photo, :update?)
        rescue Pundit::NotAuthorizedError
          errors << "Not authorized to update photo #{photo.slug}"
          next
        end

        unless photo.update(privacy: mapped_privacy)
          errors << "Failed to update photo #{photo.slug}: #{photo.errors.full_messages.join(', ')}"
        end
      end

      { photos: photos.reload, errors: }
    end

    private

    def find_photos(photo_ids)
      # Use policy scope to bypass default scope while respecting visibility for the current user
      base = Pundit.policy_scope(context[:current_user], Photo.unscoped)
      photo_ids.filter_map do |id|
        begin
          base.friendly.find(id)
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end
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
