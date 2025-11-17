# frozen_string_literal: true

class FlickrUserClaimService
  def initialize(user, flickr_user)
    @user = user
    @flickr_user = flickr_user
  end

  def request_automatic_claim
    # Generate a random 10-character verification code
    verification_code = SecureRandom.alphanumeric(10)

    FlickrUserClaim.create!(
      user: @user,
      flickr_user: @flickr_user,
      claim_type: 'automatic',
      status: 'pending',
      verification_code: verification_code
    )
  end

  def verify_automatic_claim(claim)
    return { success: false, error: 'Claim not found' } unless claim
    return { success: false, error: 'Claim is not pending' } unless claim.pending?
    return { success: false, error: 'Invalid claim type' } unless claim.automatic?

    # Fetch the Flickr profile description
    profile_description = FlickrAPIService.profile_get_profile_description(@flickr_user.nsid)

    return { success: false, error: 'Unable to fetch Flickr profile' } if profile_description.nil?

    # Check if the verification code is in the profile description
    if profile_description.include?(claim.verification_code)
      claim.update!(verified_at: Time.current)
      claim.approve!
      
      # Send email to admins about successful automatic verification
      admin_emails = User.admins.pluck(:email)
      if admin_emails.any?
        AdminMailer.with(
          admin_emails: admin_emails,
          user: @user,
          flickr_user: @flickr_user,
          claim: claim
        ).flickr_claim_approved.deliver_later
      end
      
      { success: true, claim: claim }
    else
      { success: false, error: 'Verification code not found in Flickr profile description' }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def request_manual_claim(reason: nil)
    claim = FlickrUserClaim.create!(
      user: @user,
      flickr_user: @flickr_user,
      claim_type: 'manual',
      status: 'pending',
      reason: reason
    )

    # Send email to admins
    admin_emails = User.admins.pluck(:email)
    if admin_emails.any?
      AdminMailer.with(
        admin_emails: admin_emails,
        user: @user,
        flickr_user: @flickr_user,
        claim: claim,
        reason: reason
      ).flickr_claim_request.deliver_later
    end

    claim
  end

  def approve_claim(claim)
    return { success: false, error: 'Claim not found' } unless claim
    return { success: false, error: 'Claim is not pending' } unless claim.pending?

    claim.approve!

    # Send email to user
    UserMailer.with(user: claim.user, flickr_user: claim.flickr_user)
              .flickr_claim_approved
              .deliver_later

    { success: true, claim: claim }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def deny_claim(claim)
    return { success: false, error: 'Claim not found' } unless claim
    return { success: false, error: 'Claim is not pending' } unless claim.pending?

    claim.deny!

    # Send email to user
    UserMailer.with(user: claim.user, flickr_user: claim.flickr_user)
              .flickr_claim_denied
              .deliver_later

    { success: true, claim: claim }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  class << self
    def undo_claim(claim_id)
      claim = FlickrUserClaim.find_by(id: claim_id)
      return { success: false, error: 'Claim not found' } unless claim

      # If the claim was approved, remove the claimed_by_user association
      claim.flickr_user.update!(claimed_by_user: nil) if claim.approved?

      # Delete the claim record
      claim.destroy!

      { success: true }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end
end
