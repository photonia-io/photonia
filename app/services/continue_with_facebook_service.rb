# frozen_string_literal: true

# Service class for "Continue with Facebook" related operations
class ContinueWithFacebookService
  class InvalidSignatureError < StandardError; end
  class InvalidUserInfoError < StandardError; end

  def initialize(access_token, signed_request, app_secret: ENV.fetch('PHOTONIA_FACEBOOK_APP_SECRET', nil), http_client: Net::HTTP)
    @access_token = access_token
    @signed_request = signed_request
    @app_secret = app_secret
    @http_client = http_client
    @encoded_signature, @encoded_payload = @signed_request.split('.')
  end

  def facebook_user_info
    verify_signature!
    user_info = fetch_facebook_user_info
    validate_user_info!(user_info)
    user_info
  end

  private

  def verify_signature!
    raise InvalidSignatureError unless valid_signature?
  end

  def valid_signature?
    digested_encoded_payload = OpenSSL::HMAC.digest('sha256', @app_secret, @encoded_payload)
    expected_signature = Base64.urlsafe_encode64(digested_encoded_payload).gsub('=', '')
    @encoded_signature == expected_signature
  end

  def decoded_payload
    decoded_payload = Base64.urlsafe_decode64(@encoded_payload)
    JSON.parse(decoded_payload)
  end

  def fetch_facebook_user_info
    uri = URI.parse("https://graph.facebook.com/v8.0/me?fields=email,first_name,last_name,name&access_token=#{@access_token}")
    response = @http_client.get_response(uri)
    JSON.parse(response.body)
  end

  def validate_user_info!(user_info)
    raise InvalidUserInfoError unless decoded_payload['user_id'] == user_info['id']
  end
end
