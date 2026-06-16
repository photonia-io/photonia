# frozen_string_literal: true

module Mutations
  class ApproveFlickrClaim < BaseMutation
    description 'Approve a pending Flickr user claim and link the Flickr account to the user (admin only)'

    argument :claim_id, ID, required: true, description: 'The ID of the Flickr user claim to approve'

    field :claim, Types::FlickrUserClaimType, null: true, description: 'The approved Flickr user claim'
    field :success, Boolean, null: false, description: 'Whether the claim was successfully approved'
    field :errors, [String], null: false, description: 'List of error messages if the operation failed'

    def resolve(claim_id:)
      current_user = context[:current_user]
      return { claim: nil, success: false, errors: ['You must be signed in'] } unless current_user

      claim = FlickrUserClaim.find_by(id: claim_id)
      return { claim: nil, success: false, errors: ['Claim not found'] } unless claim

      authorize(claim, :approve?)

      service = FlickrUserClaimService.new(claim.user, claim.flickr_user)
      result = service.approve_claim(claim)

      if result[:success]
        { claim: result[:claim], success: true, errors: [] }
      else
        { claim: claim, success: false, errors: [result[:error]] }
      end
    rescue Pundit::NotAuthorizedError
      { claim: nil, success: false, errors: ['Not authorized to approve claims'] }
    rescue StandardError => e
      { claim: nil, success: false, errors: [e.message] }
    end
  end
end
