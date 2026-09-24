# frozen_string_literal: true

module Mutations
  class DenyFlickrClaim < BaseMutation
    description 'Deny a pending Flickr user claim and reject the request to link the Flickr account (admin only)'

    argument :claim_id, ID, required: true, description: 'The ID of the Flickr user claim to deny'

    field :claim, Types::FlickrUserClaimType, null: true, description: 'The denied Flickr user claim'
    field :success, Boolean, null: false, description: 'Whether the claim was successfully denied'
    field :errors, [String], null: false, description: 'List of error messages if the operation failed'

    def resolve(claim_id:)
      current_user = context[:current_user]
      return { claim: nil, success: false, errors: ['You must be signed in'] } unless current_user

      claim = FlickrUserClaim.find_by(id: claim_id)
      return { claim: nil, success: false, errors: ['Claim not found'] } unless claim

      authorize(claim, :deny?)

      service = FlickrUserClaimService.new(claim.user, claim.flickr_user)
      result = service.deny_claim(claim)

      if result[:success]
        { claim: result[:claim], success: true, errors: [] }
      else
        { claim: claim, success: false, errors: [result[:error]] }
      end
    rescue Pundit::NotAuthorizedError
      { claim: nil, success: false, errors: ['Not authorized to deny claims'] }
    rescue StandardError => e
      { claim: nil, success: false, errors: [e.message] }
    end
  end
end
