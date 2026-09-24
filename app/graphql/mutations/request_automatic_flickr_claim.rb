# frozen_string_literal: true

module Mutations
  class RequestAutomaticFlickrClaim < BaseMutation
    description 'Request an automatic claim for a Flickr user. Returns a verification code that must be added to the Flickr profile description for verification.'

    argument :flickr_user_nsid, String, required: true, description: 'The NSID of the Flickr user to claim'

    field :claim, Types::FlickrUserClaimType, null: true, description: 'The created Flickr user claim with verification code'
    field :errors, [String], null: false, description: 'List of error messages if the operation failed'

    def resolve(flickr_user_nsid:)
      current_user = context[:current_user]
      return { claim: nil, errors: ['You must be signed in'] } unless current_user

      flickr_user = FlickrUser.find_by(nsid: flickr_user_nsid)
      return { claim: nil, errors: ['Flickr user not found'] } unless flickr_user

      return { claim: nil, errors: ['This Flickr user has already been claimed'] } if flickr_user.claimed_by_user_id.present?

      existing_claim = FlickrUserClaim.pending.find_by(user: current_user, flickr_user: flickr_user)
      return existing_claim_payload(existing_claim) if existing_claim

      authorize(FlickrUserClaim.new(user: current_user), :create?)

      service = FlickrUserClaimService.new(current_user, flickr_user)
      claim = service.request_automatic_claim

      { claim: claim, errors: [] }
    # No rescue Pundit::NotAuthorizedError here: FlickrUserClaimPolicy#create? is just
    # `user.present?`, and current_user is already guaranteed present above, so authorize
    # can never actually deny this - unlike the other claim mutations.
    rescue StandardError => e
      { claim: nil, errors: [e.message] }
    end

    private

    # A pending automatic claim is resumed; a pending manual one blocks a new automatic claim.
    def existing_claim_payload(claim)
      return { claim: claim, errors: [] } if claim.automatic?

      { claim: nil, errors: ['You already have a pending manual claim for this Flickr user'] }
    end
  end
end
