# frozen_string_literal: true

module Queries
  class PendingFlickrClaimsQuery < BaseQuery
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
