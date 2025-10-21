# frozen_string_literal: true

module Mutations
  # Set album privacy
  class SetAlbumPrivacy < Mutations::BaseMutation
    description 'Set album privacy'

    argument :id, String, 'Album Id', required: true
    argument :privacy, String, 'Album privacy (public, private, friends_and_family)', required: true

    type Types::AlbumType, null: false

    def resolve(id:, privacy:)
      album = find_album(id)
      raise GraphQL::ExecutionError, 'Album not found' unless album

      authorize(album, :update?)

      mapped = map_privacy_value(privacy)
      raise GraphQL::ExecutionError, 'Invalid privacy value' unless mapped

      raise GraphQL::ExecutionError, album.errors.full_messages.join(', ') unless album.update(privacy: mapped)

      album
    end

    private

    def find_album(id)
      # Use policy scope to bypass default scope while respecting visibility for the current user
      base = Pundit.policy_scope(context[:current_user], Album.unscoped)
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
