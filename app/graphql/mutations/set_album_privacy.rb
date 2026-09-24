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

      photos_updated_count = 0

      ActiveRecord::Base.transaction do
        photos_updated_count = cascade_privacy_to_photos(album) if mapped_privacy == 'private' && update_photos

        raise GraphQL::ExecutionError, album.errors.full_messages.join(', ') unless album.update(privacy: mapped_privacy)
      end

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
      end
    end

    # Sets every non-private photo in the album to private, and re-runs
    # maintenance on any other album sharing one of those photos so their
    # public_photos_count / public_cover_photo_id stay in sync.
    def cascade_privacy_to_photos(album)
      photo_ids = non_private_photo_ids(album)
      return 0 if photo_ids.empty?

      # rubocop:disable Rails/SkipsModelValidations
      Photo.unscoped.where(id: photo_ids).update_all(privacy: 'private', updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations

      refresh_other_albums(album, photo_ids)

      photo_ids.size
    end

    def non_private_photo_ids(album)
      Photo.unscoped
           .where(id: album.albums_photos.select(:photo_id))
           .where.not(privacy: 'private')
           .pluck(:id)
    end

    def refresh_other_albums(album, photo_ids)
      other_album_ids = AlbumsPhoto.where(photo_id: photo_ids).distinct.pluck(:album_id) - [album.id]
      Album.unscoped.where(id: other_album_ids).find_each(&:maintenance)
    end
  end
end
