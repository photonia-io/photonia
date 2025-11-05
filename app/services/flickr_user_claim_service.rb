# frozen_string_literal: true

class FlickrUserClaimService
  def initialize(user, flickr_user)
    @user = user
    @flickr_user = flickr_user
  end

  def request_automatic_claim
    # Generate a random 10-character verification code
    verification_code = SecureRandom.alphanumeric(10)

    claim = FlickrUserClaim.create!(
      user: @user,
      flickr_user: @flickr_user,
      claim_type: 'automatic',
      status: 'pending',
      verification_code: verification_code
    )

    claim
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
    def approve_claim_by_token(claim_id, token)
      claim = FlickrUserClaim.find_by(id: claim_id)
      return { success: false, error: 'Claim not found' } unless claim

      # Verify token (using the claim's ID and timestamps)
      expected_token = generate_token(claim)
      return { success: false, error: 'Invalid token' } unless token == expected_token

      service = new(claim.user, claim.flickr_user)
      service.approve_claim(claim)
    end

    def deny_claim_by_token(claim_id, token)
      claim = FlickrUserClaim.find_by(id: claim_id)
      return { success: false, error: 'Claim not found' } unless claim

      # Verify token
      expected_token = generate_token(claim)
      return { success: false, error: 'Invalid token' } unless token == expected_token

      service = new(claim.user, claim.flickr_user)
      service.deny_claim(claim)
    end

    def generate_token(claim)
      # Simple token generation using Rails secret key base
      data = "#{claim.id}-#{claim.created_at.to_i}"
      Digest::SHA256.hexdigest("#{Rails.application.secret_key_base}-#{data}")[0..31]
    end
  end
end
