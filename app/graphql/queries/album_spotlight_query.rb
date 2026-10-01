# frozen_string_literal: true

module Queries
  # The album featured on the homepage: the one picked in the admin settings,
  # or the newest album when none is picked (or the pick is no longer visible)
  class AlbumSpotlightQuery < BaseQuery
    description 'The album spotlighted on the homepage'

    type Types::AlbumType, null: true

    def resolve
      visible = Album.where('albums.public_photos_count > 0')
      slug = Setting.homepage_spotlight_album_id

      (visible.find_by(slug:) if slug.present?) || visible.order(created_at: :desc).first
    end
  end
end
