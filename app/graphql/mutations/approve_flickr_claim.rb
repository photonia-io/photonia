# frozen_string_literal: true

module Mutations
  class ApproveFlickrClaim < BaseMutation
    description 'Approve a Flickr user claim (admin only)'

    argument :claim_id, ID, required: true

    field :claim, Types::FlickrUserClaimType, null: true
    field :success, Boolean, null: false
    field :errors, [String], null: false

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
