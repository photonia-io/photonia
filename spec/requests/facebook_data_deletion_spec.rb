# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FacebookDataDeletion' do
  let(:app_secret) { 'test_app_secret' }
  let(:user_id) { '12345' }
  let(:payload) { { 'user_id' => user_id, 'algorithm' => 'HMAC-SHA256' } }
  let(:encoded_payload) { Base64.urlsafe_encode64(payload.to_json) }
  let(:signature) do
    digested = OpenSSL::HMAC.digest('sha256', app_secret, encoded_payload)
    Base64.urlsafe_encode64(digested).gsub('=', '')
  end
  let(:signed_request) { "#{signature}.#{encoded_payload}" }

  before do
    allow(ENV).to receive(:fetch).with('PHOTONIA_FACEBOOK_APP_SECRET').and_return(app_secret)
  end

  describe 'POST /facebook_data_deletion/callback' do
    context 'with valid signed request' do
      it 'returns success with confirmation URL and code' do
        post '/facebook_data_deletion/callback', params: { signed_request: signed_request }
        
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['url']).to include('/facebook_data_deletion/status?id=')
        expect(json['confirmation_code']).to be_present
      end

      context 'when user exists with facebook_user_id' do
        let!(:user) { create(:user, facebook_user_id: user_id, email: 'test@facebook.com') }

        it 'finds the user and logs the deletion request' do
          allow(Rails.logger).to receive(:info)
          
          post '/facebook_data_deletion/callback', params: { signed_request: signed_request }
          
          expect(response).to have_http_status(:ok)
          expect(Rails.logger).to have_received(:info).with("Facebook data deletion request received for user_id: #{user_id}")
          expect(Rails.logger).to have_received(:info).with("Found user with email: #{user.email}")
        end
      end

      context 'when user does not exist' do
        it 'logs that no user was found' do
          allow(Rails.logger).to receive(:info)
          
          post '/facebook_data_deletion/callback', params: { signed_request: signed_request }
          
          expect(response).to have_http_status(:ok)
          expect(Rails.logger).to have_received(:info).with("No user found with facebook_user_id: #{user_id}")
        end
      end
    end

    context 'with invalid signed request' do
      let(:invalid_signed_request) { "invalid_signature.#{encoded_payload}" }

      it 'returns unauthorized' do
        post '/facebook_data_deletion/callback', params: { signed_request: invalid_signed_request }
        
        expect(response).to have_http_status(:unauthorized)
        json = response.parsed_body
        expect(json['error']).to eq('Invalid signature')
      end
    end

    context 'with missing signed_request parameter' do
      it 'returns bad request' do
        post '/facebook_data_deletion/callback'
        
        expect(response).to have_http_status(:bad_request)
        json = response.parsed_body
        expect(json['error']).to eq('Missing signed_request parameter')
      end
    end

    context 'with malformed signed request' do
      let(:malformed_signed_request) { 'no_dot_separator' }

      it 'returns unauthorized' do
        post '/facebook_data_deletion/callback', params: { signed_request: malformed_signed_request }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /facebook_data_deletion/status' do
    let(:confirmation_code) { 'abc123' }

    it 'returns success with confirmation message' do
      get '/facebook_data_deletion/status', params: { id: confirmation_code }
      
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['message']).to eq('Data deletion request received')
      expect(json['confirmation_code']).to eq(confirmation_code)
    end
  end
end
