# frozen_string_literal: true

module Mutations
  class RequestManualFlickrClaim < BaseMutation
    description 'Request a manual claim for a Flickr user. This is used when the user cannot access their Flickr account. An admin must approve the claim.'

    argument :flickr_user_nsid, String, required: true, description: 'The NSID of the Flickr user to claim'
    argument :reason, String, required: false, description: 'Optional reason for requesting manual claim (e.g., lost access to Flickr account)'

    field :claim, Types::FlickrUserClaimType, null: true, description: 'The created Flickr user claim pending admin approval'
    field :errors, [String], null: false, description: 'List of error messages if the operation failed'

    def resolve(flickr_user_nsid:, reason: nil)
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
      claim = service.request_manual_claim(reason: reason)

      { claim: claim, errors: [] }
    rescue Pundit::NotAuthorizedError
      { claim: nil, errors: ['Not authorized to create claim'] }
    rescue StandardError => e
      { claim: nil, errors: [e.message] }
    end
  end
end
