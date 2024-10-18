# frozen_string_literal: true

require 'rails_helper'

describe ContinueWithFacebookService, type: :service do
  let(:access_token) { 'facebook_access_token' }
  let(:encoded_signature) { 'encoded_signature' }
  let(:encoded_payload) { 'encoded_payload' }
  let(:signed_request) { "#{encoded_signature}.#{encoded_payload}" }

  subject { described_class.new(access_token, signed_request) }

  describe '#verify_signature' do
    let(:facebook_app_secret) { 'secret' }
    let(:digested_encoded_payload) { 'digest' }

    before do
      ENV['PHOTONIA_FACEBOOK_APP_SECRET'] = facebook_app_secret
    end

    it 'verifies the signature' do
      expect(OpenSSL::HMAC).to receive(:digest).with('sha256', facebook_app_secret, encoded_payload).and_return(digested_encoded_payload)
      expect(Base64).to receive(:urlsafe_encode64).with(digested_encoded_payload).and_return(encoded_signature)
      expect(subject.verify_signature).to be_truthy
    end
  end

  describe '#get_decoded_payload' do
    it 'decodes the payload' do
      expect(Base64).to receive(:urlsafe_decode64).with(encoded_payload).and_return('{"key": "value"}')
      expect(subject.get_decoded_payload).to eq('key' => 'value')
    end
  end

  describe '#fetch_facebook_user_info' do
    let(:response) { double('response', body: '{"key": "value"}') }
    let(:uri) { URI.parse("https://graph.facebook.com/v8.0/me?fields=email,first_name,last_name,name&access_token=#{access_token}") }

    it 'fetches the user info' do
      expect(Net::HTTP).to receive(:get_response).with(uri).and_return(response)
      expect(subject.fetch_facebook_user_info).to eq('key' => 'value')
    end
  end
end
