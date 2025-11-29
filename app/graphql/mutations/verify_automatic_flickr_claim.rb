# frozen_string_literal: true

module Mutations
  class VerifyAutomaticFlickrClaim < BaseMutation
    description 'Verify an automatic Flickr user claim by checking if the verification code is present in the Flickr profile description. If verified, the claim is approved automatically.'

    argument :claim_id, ID, required: true, description: 'The ID of the Flickr user claim to verify'

    field :claim, Types::FlickrUserClaimType, null: true, description: 'The verified Flickr user claim (with updated status)'
    field :success, Boolean, null: false, description: 'Whether the verification was successful'
    field :errors, [String], null: false, description: 'List of error messages if the verification failed'

    def resolve(claim_id:)
      current_user = context[:current_user]
      return { claim: nil, success: false, errors: ['You must be signed in'] } unless current_user

      claim = FlickrUserClaim.find_by(id: claim_id)
      return { claim: nil, success: false, errors: ['Claim not found'] } unless claim

      authorize(claim, :verify?)

      service = FlickrUserClaimService.new(current_user, claim.flickr_user)
      result = service.verify_automatic_claim(claim)

      if result[:success]
        { claim: result[:claim], success: true, errors: [] }
      else
        { claim: claim, success: false, errors: [result[:error]] }
      end
    rescue Pundit::NotAuthorizedError
      { claim: nil, success: false, errors: ['Not authorized to verify this claim'] }
    rescue StandardError => e
      { claim: nil, success: false, errors: [e.message] }
    end
  end
end
