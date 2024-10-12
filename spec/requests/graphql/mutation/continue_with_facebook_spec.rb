# frozen_string_literal: true

require 'rails_helper'

describe 'continueWithFacebook Mutation', type: :request do
  let(:facebook_user_id) { 123 }
  let(:email) { 'test@test.com' }
  let(:first_name) { 'Test' }
  let(:last_name) { 'User' }
  let(:display_name) { 'Test User' }

  before do
    allow_any_instance_of(ContinueWithFacebookService).to receive(:verify_signature).and_return(true)
    allow_any_instance_of(ContinueWithFacebookService).to receive(:get_decoded_payload).and_return('user_id' => facebook_user_id)
    allow_any_instance_of(ContinueWithFacebookService).to receive(:fetch_facebook_user_info).and_return(
      'id' => facebook_user_id,
      'email' => email,
      'first_name' => first_name,
      'last_name' => last_name,
      'name' => display_name
    )
  end

  let(:query) do
    <<~GQL
      mutation {
        continueWithFacebook(
          accessToken: "facebook_access_token"
          signedRequest: "facebook_signed_request"
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
      data = json['data']['continueWithFacebook']

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
      data = json['data']['continueWithFacebook']

      expect(data['email']).to eq(email)
      expect(data['admin']).to eq(false)
    end
  end
end
