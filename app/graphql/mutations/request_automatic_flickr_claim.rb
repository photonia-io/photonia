# frozen_string_literal: true

module Mutations
  class RequestAutomaticFlickrClaim < BaseMutation
    description 'Request an automatic claim for a Flickr user'

    argument :flickr_user_nsid, String, required: true

    field :claim, Types::FlickrUserClaimType, null: true
    field :errors, [String], null: false

    def resolve(flickr_user_nsid:)
      current_user = context[:current_user]
      return { claim: nil, errors: ['You must be signed in'] } unless current_user

      flickr_user = FlickrUser.find_by(nsid: flickr_user_nsid)
      return { claim: nil, errors: ['Flickr user not found'] } unless flickr_user

      if flickr_user.claimed_by_user_id.present?
        return { claim: nil, errors: ['This Flickr user has already been claimed'] }
      end

      # Check if user already has a pending claim for this Flickr user
      existing_claim = FlickrUserClaim.find_by(user: current_user, flickr_user: flickr_user, status: 'pending')
      if existing_claim
        return { claim: existing_claim, errors: [] }
      end

      authorize(FlickrUserClaim.new(user: current_user), :create?)

      service = FlickrUserClaimService.new(current_user, flickr_user)
      claim = service.request_automatic_claim

      { claim: claim, errors: [] }
    rescue Pundit::NotAuthorizedError
      { claim: nil, errors: ['Not authorized to create claim'] }
    rescue StandardError => e
      { claim: nil, errors: [e.message] }
    end
  end
end
