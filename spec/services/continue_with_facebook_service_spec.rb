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
    let(:response) { instance_double(Net::HTTPResponse, body: facebook_user_info.to_json) }

    before do
      allow(instance).to receive_messages(valid_signature?: true, decoded_payload: decoded_payload)
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

  describe 'private methods' do
    describe '#valid_signature?' do
      context 'when the signature is valid' do
        # Generated from @encoded_payload using @app_secret
        let(:encoded_signature) { '5rn1iaby6JxCF6oREuU4ie_wbdCECEXE1ajpXQNUgt8' }

        it 'returns true' do
          expect(instance.send(:valid_signature?)).to eq(true)
        end
      end

      context 'when the signature is invalid' do
        let(:encoded_signature) { 'invalid_signature' }

        it 'returns false' do
          expect(instance.send(:valid_signature?)).to eq(false)
        end
      end
    end

    describe '#decoded_payload' do
      let(:payload) { { 'user_id' => 123 } }
      let(:encoded_payload) { Base64.urlsafe_encode64(payload.to_json) }

      it 'decodes the payload' do
        expect(instance.send(:decoded_payload)).to eq(payload)
      end
    end
  end
end
