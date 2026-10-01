# frozen_string_literal: true

module Queries
  # Totals over the public archive. Never user-specific, so one cached copy
  # serves every visitor.
  class HomepageStatsQuery < BaseQuery
    description 'Public archive totals and per-year photo counts'

    type Types::HomepageStatsType, null: false

    CACHE_KEY = 'homepage_stats/v1'
    CACHE_TTL = 1.hour

    def resolve
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { compute }
    end

    private

    # Photo/Album default scopes already limit these to public records.
    def compute
      years = Photo.where.not(taken_at: nil)
                   .group(Arel.sql('EXTRACT(YEAR FROM photos.taken_at)::int'))
                   .count
                   .map { |year, count| { year:, count: } }
                   .sort_by { |entry| -entry[:year] }

      {
        photos_count: Photo.count,
        albums_count: Album.where('albums.public_photos_count > 0').count,
        views_count: Photo.sum('photos.impressions_count + photos.flickr_impressions_count'),
        first_year: years.last&.fetch(:year),
        last_year: years.first&.fetch(:year),
        years:
      }
    end
  end
end
