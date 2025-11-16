# frozen_string_literal: true

module Queries
  class MyFlickrClaimsQuery < BaseQuery
    type [Types::FlickrUserClaimType], null: false

    def resolve
      current_user = context[:current_user]
      return [] unless current_user

      FlickrUserClaim.where(user: current_user).order(created_at: :desc)
    end
  end
end
