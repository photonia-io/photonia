# frozen_string_literal: true

module Queries
  class FlickrUserClaimQuery < BaseQuery
    type Types::FlickrUserClaimType, null: true

    argument :id, ID, required: true

    def resolve(id:)
      current_user = context[:current_user]
      return nil unless current_user

      claim = FlickrUserClaim.find_by(id: id)
      return nil unless claim

      authorize(claim, :show?)
      claim
    rescue Pundit::NotAuthorizedError
      nil
    end
  end
end
