# frozen_string_literal: true

module Mutations
  # Set album privacy
  class SetAlbumPrivacy < Mutations::BaseMutation
    description 'Set album privacy'

    argument :id, String, 'Album Id', required: true
    argument :privacy, String, 'Album privacy (public, private, friends_and_family)', required: true
    argument :update_photos, Boolean, 'Whether to update contained photos privacy', required: false, default_value: false

    field :album, Types::AlbumType, null: false
    field :photos_updated_count, Integer, null: false

    def resolve(id:, privacy:, update_photos: false)
      album = find_album(id)
      raise GraphQL::ExecutionError, 'Album not found' unless album

      authorize(album, :update?)

      mapped_privacy = map_privacy_value(privacy)
      raise GraphQL::ExecutionError, 'Invalid privacy value' unless mapped_privacy

      old_privacy = album.privacy
      photos_updated_count = 0

      # If changing to private and update_photos is true, update all album photos to private
      if mapped_privacy == 'private' && update_photos && old_privacy != 'private'
        photos_updated_count = update_album_photos_privacy(album, 'private')
      end

      raise GraphQL::ExecutionError, album.errors.full_messages.join(', ') unless album.update(privacy: mapped_privacy)

      { album:, photos_updated_count: }
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

    def update_album_photos_privacy(album, privacy)
      photos = album.all_photos(select: false, refetch: true)
      updated_count = 0

      photos.each do |photo|
        next unless photo.update(privacy:)

        updated_count += 1
      end

      updated_count
    end
  end
end
