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

    def resolve(id:, privacy:, update_photos:)
      album = find_album(id)

      authorize(album, :update?)

      raise GraphQL::ExecutionError, 'Invalid privacy value' unless Album.privacies.key?(privacy)

      photos_updated_count = 0

      ActiveRecord::Base.transaction do
        photos_updated_count = cascade_privacy_to_photos(album) if privacy == 'private' && update_photos

        raise GraphQL::ExecutionError, album.errors.full_messages.join(', ') unless album.update(privacy:)
      end

      { album:, photos_updated_count: }
    end

    private

    def find_album(id)
      # Use policy scope to bypass default scope while respecting visibility for the current user
      Pundit.policy_scope(context[:current_user], Album.unscoped).friendly.find(id)
    end

    # Sets every non-private photo in the album to private, and re-runs
    # maintenance on any other album sharing one of those photos so their
    # public_photos_count / public_cover_photo_id stay in sync.
    def cascade_privacy_to_photos(album)
      photo_ids = album.non_private_photos.pluck(:id)
      return 0 if photo_ids.empty?

      # rubocop:disable Rails/SkipsModelValidations
      Photo.unscoped.where(id: photo_ids).update_all(privacy: 'private', updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations

      Album.maintain_containing(photo_ids, except: album.id)

      photo_ids.size
    end
  end
end
