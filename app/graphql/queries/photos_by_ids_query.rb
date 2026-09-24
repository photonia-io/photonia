# frozen_string_literal: true

module Queries
  # Batch-fetches photos by slug, for the upload page's processing poller.
  # Unlike PhotoQuery, this records no impressions - it's polled repeatedly
  # for the same photos, which impressions are not meant to count.
  class PhotosByIdsQuery < BaseQuery
    description 'Find photos by ID (slug), skipping unknown or inaccessible ones'

    type [Types::PhotoType], null: false

    argument :ids, [ID], 'IDs (slugs) of the photos', required: true

    MAX_IDS = 100

    def resolve(ids:)
      slugs = ids.first(MAX_IDS)
      Pundit.policy_scope(current_user, Photo.unscoped).where(slug: slugs)
    end
  end
end
