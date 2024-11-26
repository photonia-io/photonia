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

  context 'when continue with facebook is enabled' do
    before do
      Setting.continue_with_facebook_enabled = true
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

      it "sets the user's signup provider to 'facebook'" do
        post_mutation
        user = User.last
        expect(user.signup_provider).to eq('facebook')
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

    context 'when the signature is invalid' do
      before do
        allow_any_instance_of(ContinueWithFacebookService).to receive(:verify_signature).and_return(false)
      end

      it 'raises an error' do
        expect { post_mutation }.to raise_error('Invalid signature')
      end
    end

    context 'when the decoded payload user id does not match the user info id' do
      before do
        allow_any_instance_of(ContinueWithFacebookService).to receive(:get_decoded_payload).and_return('user_id' => 456)
      end

      it 'raises an error' do
        expect { post_mutation }.to raise_error('Invalid user info')
      end
    end
  end

  context 'when continue with facebook is disabled' do
    before do
      Setting.continue_with_facebook_enabled = false
    end

    it 'raises an error' do
      expect { post_mutation }.to raise_error('Continue with Facebook is disabled')
    end
  end
end
