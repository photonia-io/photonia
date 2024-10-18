# frozen_string_literal: true

# Service class for "Continue with Facebook" related operations
class ContinueWithFacebookService
  def initialize(access_token, signed_request)
    @access_token = access_token
    @signed_request = signed_request
    @encoded_signature, @encoded_payload = @signed_request.split('.')
  end

  def verify_signature
    # Create a SHA256 digest of the encoded_payload using the FB app secret
    digested_encoded_payload = OpenSSL::HMAC.digest('sha256', ENV['PHOTONIA_FACEBOOK_APP_SECRET'], @encoded_payload)
    # Base64 encode the digest and remove any trailing '='
    expected_signature = Base64.urlsafe_encode64(digested_encoded_payload).gsub('=', '')

    @encoded_signature == expected_signature
  end

  def get_decoded_payload
    decoded_payload = Base64.urlsafe_decode64(@encoded_payload)
    JSON.parse(decoded_payload)
  end

  def fetch_facebook_user_info
    uri = URI.parse("https://graph.facebook.com/v8.0/me?fields=email,first_name,last_name,name&access_token=#{@access_token}")
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)
  end
end
