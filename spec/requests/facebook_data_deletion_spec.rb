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

      context 'when user exists with facebook_user_id and created_from_facebook is true' do
        let!(:user) { create(:user, facebook_user_id: user_id, email: 'test@facebook.com', created_from_facebook: true) }

        it 'disables the user and clears facebook_user_id' do
          allow(Rails.logger).to receive(:info)

          post '/facebook_data_deletion/callback', params: { signed_request: signed_request }

          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.facebook_user_id).to be_nil
          expect(user.disabled).to be(true)
          expect(user.facebook_data_deletion_code).to be_present
        end

        it 'logs the deletion request' do
          allow(Rails.logger).to receive(:info)

          post '/facebook_data_deletion/callback', params: { signed_request: signed_request }

          expect(Rails.logger).to have_received(:info).with("Facebook data deletion request received for user_id: #{user_id}")
          expect(Rails.logger).to have_received(:info).with("Found user with email: #{user.email}")
          expect(Rails.logger).to have_received(:info).with("User #{user.email} has been disabled and unlinked from Facebook")
        end
      end

      context 'when user exists with facebook_user_id and created_from_facebook is false' do
        let!(:user) { create(:user, facebook_user_id: user_id, email: 'existing@user.com', created_from_facebook: false) }

        it 'unlinks from Facebook but does not disable the user' do
          allow(Rails.logger).to receive(:info)

          post '/facebook_data_deletion/callback', params: { signed_request: signed_request }

          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.facebook_user_id).to be_nil
          expect(user.disabled).to be(false)
          expect(user.facebook_data_deletion_code).to be_present
        end

        it 'logs the unlink action' do
          allow(Rails.logger).to receive(:info)

          post '/facebook_data_deletion/callback', params: { signed_request: signed_request }

          expect(Rails.logger).to have_received(:info).with("Facebook data deletion request received for user_id: #{user_id}")
          expect(Rails.logger).to have_received(:info).with("Found user with email: #{user.email}")
          expect(Rails.logger).to have_received(:info).with("User #{user.email} has been unlinked from Facebook")
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

    context 'when JSON parsing fails' do
      let(:invalid_json_payload) { Base64.urlsafe_encode64('not valid json') }
      let(:signature_for_invalid_json) do
        digested = OpenSSL::HMAC.digest('sha256', app_secret, invalid_json_payload)
        Base64.urlsafe_encode64(digested).gsub('=', '')
      end
      let(:signed_request_with_invalid_json) { "#{signature_for_invalid_json}.#{invalid_json_payload}" }

      it 'returns internal server error' do
        allow(Rails.logger).to receive(:error)

        post '/facebook_data_deletion/callback', params: { signed_request: signed_request_with_invalid_json }

        expect(response).to have_http_status(:internal_server_error)
        json = response.parsed_body
        expect(json['error']).to eq('Internal server error')
        expect(Rails.logger).to have_received(:error).with(/Error processing Facebook data deletion request/)
      end
    end
  end

  describe 'GET /facebook_data_deletion/status' do
    let(:confirmation_code) { 'abc123' }

    context 'when no user has the confirmation code' do
      it 'returns generic confirmation message' do
        get '/facebook_data_deletion/status', params: { id: confirmation_code }

        expect(response).to have_http_status(:not_found)
        json = response.parsed_body
        expect(json['message']).to eq('Confirmation code not found.')
        expect(json['confirmation_code']).to eq(confirmation_code)
      end
    end

    context 'when user was created from Facebook' do
      let!(:user) { create(:user, facebook_data_deletion_code: confirmation_code, created_from_facebook: true, disabled: true) }

      it 'returns disabled user message' do
        get '/facebook_data_deletion/status', params: { id: confirmation_code }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['status']).to eq('completed')
        expect(json['message']).to eq('Your data deletion request was completed. The user has been disabled.')
      end
    end

    context 'when user was not created from Facebook' do
      let!(:user) { create(:user, facebook_data_deletion_code: confirmation_code, created_from_facebook: false, disabled: false) }

      it 'returns unlinked message' do
        get '/facebook_data_deletion/status', params: { id: confirmation_code }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['status']).to eq('completed')
        expect(json['message']).to eq("Your data deletion request was completed. The user's link with Facebook was removed.")
      end
    end
  end
end
