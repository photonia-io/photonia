# frozen_string_literal: true

require 'rails_helper'

describe 'continueWithGoogle Mutation', type: :request do
  let (:email) { 'test@test.com' }
  let (:first_name) { 'Test' }
  let (:last_name) { 'User' }
  let (:display_name) { 'Test User' }

  before do
    allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(
      'email' => email,
      'email_verified' => true,
      'given_name' => first_name,
      'family_name' => last_name,
      'name' => display_name
    )
  end

  let(:query) do
    <<~GQL
      mutation {
        continueWithGoogle(
          credential: "google_credential_jwt"
          clientId: "google_client_id"
        ) {
          email
          admin
        }
      }
    GQL
  end

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  context 'when continue with google is enabled' do
    before do
      Setting.continue_with_google_enabled = true
    end

    context 'when the user does not exist' do
      before do
        # this is for the mailer
        allow(User).to receive_message_chain(:admins, :pluck).and_return(['admin@test.com'])
      end

      it 'creates a new user and sends an email to the admin' do
        Sidekiq::Testing.inline! do
          expect { post_mutation }.to change(User, :count).by(1)
            .and change(ActionMailer::Base.deliveries, :count).by(1)
        end
      end

      it "sets the user's signup provider to 'google'" do
        post_mutation
        user = User.last
        expect(user.signup_provider).to eq('google')
      end

      it 'returns the user' do
        post_mutation
        json = JSON.parse(response.body)
        data = json['data']['continueWithGoogle']

        expect(data['email']).to eq(email)
        expect(data['admin']).to eq(false)
      end
    end

    context 'when the user exists' do
      let!(:user) { create(:user, email: email) }

      it 'does not create a new user' do
        expect { post_mutation }.not_to change(User, :count)
      end

      it 'returns the user' do
        post_mutation
        json = JSON.parse(response.body)
        data = json['data']['continueWithGoogle']

        expect(data['email']).to eq(email)
        expect(data['admin']).to eq(false)
      end
    end
  end

  context 'when continue with google is disabled' do
    before do
      Setting.continue_with_google_enabled = false
    end

    it 'raises an error' do
      expect { post_mutation }.to raise_error('Continue with Google is disabled')
    end
  end
end
