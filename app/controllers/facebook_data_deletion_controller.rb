# frozen_string_literal: true

# Controller for Facebook Data Deletion Request Callback
# See: https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback
class FacebookDataDeletionController < ActionController::Base
  # Skip CSRF verification for this endpoint as it's called by Facebook
  skip_before_action :verify_authenticity_token

  def callback
    signed_request = params[:signed_request]

    if signed_request.blank?
      render json: { error: 'Missing signed_request parameter' }, status: :bad_request
      return
    end

    begin
      user_id = verify_and_extract_user_id(signed_request)
      log_deletion_request(user_id)
      confirmation_code = generate_confirmation_code(user_id)

      render json: {
        url: "#{request.base_url}/facebook_data_deletion/status?id=#{confirmation_code}",
        confirmation_code: confirmation_code
      }, status: :ok
    rescue InvalidSignatureError => e
      Rails.logger.error("Invalid Facebook signature: #{e.message}")
      render json: { error: 'Invalid signature' }, status: :unauthorized
    rescue StandardError => e
      Rails.logger.error("Error processing Facebook data deletion request: #{e.message}")
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  def status
    confirmation_code = params[:id]
    render json: {
      message: 'Data deletion request received',
      confirmation_code: confirmation_code
    }, status: :ok
  end

  private

  class InvalidSignatureError < StandardError; end

  def log_deletion_request(user_id)
    Rails.logger.info("Facebook data deletion request received for user_id: #{user_id}")

    user = User.find_by(facebook_user_id: user_id)
    if user
      # In a real implementation, you might want to:
      # - Queue a job to delete user data
      # - Anonymize the user data
      # - Mark the user for deletion
      Rails.logger.info("Found user with email: #{user.email}")
    else
      Rails.logger.info("No user found with facebook_user_id: #{user_id}")
    end
  end

  def verify_and_extract_user_id(signed_request)
    encoded_signature, encoded_payload = signed_request.split('.')

    raise InvalidSignatureError, 'Invalid signed_request format' if encoded_signature.blank? || encoded_payload.blank?

    verify_signature(encoded_signature, encoded_payload)
    extract_user_id_from_payload(encoded_payload)
  end

  def verify_signature(encoded_signature, encoded_payload)
    app_secret = ENV.fetch('PHOTONIA_FACEBOOK_APP_SECRET')
    digested_encoded_payload = OpenSSL::HMAC.digest('sha256', app_secret, encoded_payload)
    expected_signature = Base64.urlsafe_encode64(digested_encoded_payload).gsub('=', '')

    return if ActiveSupport::SecurityUtils.secure_compare(encoded_signature, expected_signature)

    raise InvalidSignatureError, 'Signature verification failed'
  end

  def extract_user_id_from_payload(encoded_payload)
    decoded_payload = Base64.urlsafe_decode64(encoded_payload)
    payload = JSON.parse(decoded_payload)

    user_id = payload['user_id']
    raise InvalidSignatureError, 'Missing user_id in payload' if user_id.blank?

    user_id
  end

  def generate_confirmation_code(user_id)
    # Generate a unique confirmation code
    Digest::SHA256.hexdigest("#{user_id}-#{Time.current.to_i}-#{SecureRandom.hex(8)}")
  end
end
