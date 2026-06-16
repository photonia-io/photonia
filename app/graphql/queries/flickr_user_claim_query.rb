# frozen_string_literal: true

module Queries
  class FlickrUserClaimQuery < BaseQuery
    description 'Get a specific Flickr user claim by ID. Only accessible to the claim owner or admins.'
    
    type Types::FlickrUserClaimType, null: true

    argument :id, ID, required: true, description: 'The ID of the Flickr user claim to retrieve'

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
