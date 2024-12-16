# frozen_string_literal: true

require 'rails_helper'

describe ContinueWithFacebookService, type: :service do
  subject(:instance) { described_class.new(access_token, signed_request, app_secret: app_secret, http_client: http_client) }

  let(:access_token) { 'facebook_access_token' }
  let(:encoded_signature) { 'encoded_signature' }
  let(:encoded_payload) { 'encoded_payload' }
  let(:signed_request) { "#{encoded_signature}.#{encoded_payload}" }
  let(:app_secret) { 'secret' }
  let(:http_client) { Net::HTTP }

  describe '#facebook_user_info' do
    let(:facebook_user_info) { { 'id' => 123 } }
    let(:decoded_payload) { { 'user_id' => 123 } }
    let(:response) { double('response', body: facebook_user_info.to_json) }

    before do
      allow(instance).to receive(:valid_signature?).and_return(true)
      allow(instance).to receive(:decoded_payload).and_return(decoded_payload)
      allow(http_client).to receive(:get_response).and_return(response)
    end

    it 'fetches the Facebook user info' do
      expect(instance.facebook_user_info).to eq(facebook_user_info)
    end

    context 'when the user info does not match the signed request' do
      let(:decoded_payload) { { 'user_id' => 456 } }

      it 'raises an InvalidUserInfoError' do
        expect { instance.facebook_user_info }.to raise_error(ContinueWithFacebookService::InvalidUserInfoError)
      end
    end

    context 'when the signature is invalid' do
      before do
        allow(instance).to receive(:valid_signature?).and_return(false)
      end

      it 'raises an InvalidSignatureError' do
        expect { instance.facebook_user_info }.to raise_error(ContinueWithFacebookService::InvalidSignatureError)
      end
    end
  end
end
