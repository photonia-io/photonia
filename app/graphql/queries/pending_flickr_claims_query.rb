# frozen_string_literal: true

module Queries
  class PendingFlickrClaimsQuery < BaseQuery
    description 'Get all pending Flickr user claims that require admin review, ordered by creation date (most recent first). Admin only.'
    
    type [Types::FlickrUserClaimType], null: false

    def resolve
      current_user = context[:current_user]
      return [] unless current_user&.admin?

      authorize(FlickrUserClaim, :index?)
      FlickrUserClaim.pending.order(created_at: :desc)
    rescue Pundit::NotAuthorizedError
      []
    end
  end
end
