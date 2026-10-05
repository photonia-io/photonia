# frozen_string_literal: true

# Resolves a share link (album slug + token) to what it unlocks, independent
# of Pundit: an album's share link bypasses the default_scope/policy visibility
# checks entirely, since the whole point is to let a visitor in without an
# account. See Album#share_token_matches? and #1181.
class AlbumShareAccess
  attr_reader :album

  def self.resolve(slug, token)
    return nil if slug.blank? || token.blank?

    album = Album.unscoped.friendly.find(slug)
    return nil unless album.share_token_matches?(token)

    new(album)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def initialize(album)
    @album = album
  end

  def covers_album?(other_album)
    other_album.id == album.id
  end

  def all_photos?
    album.all_photos_share_mode?
  end

  # Every photo in the album, at any privacy level - only meaningful to use
  # when all_photos? is true.
  def photo_scope
    album.photos.unscope(where: :privacy)
  end

  # True when this link covers `photo`: either it unlocks every photo in the
  # album, or the photo is public (and so already visible to anyone who can
  # see the album at all, in public_photos mode).
  def covers_photo?(photo)
    return false unless photo_scope.exists?(id: photo.id)

    all_photos? || photo.public?
  end
end
