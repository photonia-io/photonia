# frozen_string_literal: true

module Queries
  class PendingFlickrClaimsQuery < BaseQuery
    description 'Get all pending Flickr user claims that require admin review, ordered by creation date (most recent first). Admin only.'

    type [Types::FlickrUserClaimType], null: false

    def resolve
      current_user = context[:current_user]
      return [] unless current_user&.admin?

      # authorize can't actually raise here - FlickrUserClaimPolicy#index? is
      # exactly `user&.admin?`, already checked above - but kept for defense
      # in depth in case the policy ever grows more conditions.
      authorize(FlickrUserClaim, :index?)
      FlickrUserClaim.pending.order(created_at: :desc)
    end
  end
end
