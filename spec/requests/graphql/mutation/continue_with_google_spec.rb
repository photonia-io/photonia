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

  context 'when the user does not exist' do
    it 'creates a new user' do
      expect { post_mutation }.to change(User, :count).by(1)
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
