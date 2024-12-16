# frozen_string_literal: true

require 'rails_helper'

describe 'continueWithFacebook Mutation', type: :request do
  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:facebook_user_id) { 123 }
  let(:email) { 'test@test.com' }
  let(:first_name) { 'Test' }
  let(:last_name) { 'User' }
  let(:display_name) { 'Test User' }

  let(:cwfs_instance) { instance_double(ContinueWithFacebookService) }
  let(:expected_user_attributes) do
    {
      email: email,
      first_name: first_name,
      last_name: last_name,
      display_name: display_name
    }
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

  before do
    allow(ContinueWithFacebookService).to receive(:new).and_return(cwfs_instance)
    allow(cwfs_instance).to receive(:facebook_user_info).and_return(
      'id' => facebook_user_id,
      'email' => email,
      'first_name' => first_name,
      'last_name' => last_name,
      'name' => display_name
    )
  end

  context 'when continue with facebook is enabled' do
    before do
      Setting.continue_with_facebook_enabled = true
    end

    context 'when the user does not exist' do
      let(:admins_arr) { instance_double(ActiveRecord::Relation) }

      before do
        # this is for the mailer
        allow(User).to receive(:admins).and_return(admins_arr)
        allow(admins_arr).to receive(:pluck).and_return(['admin@test.com'])
      end

      it 'creates a new user with the correct attributes' do
        expect { post_mutation }.to change(User, :count).by(1)
        expect(User.last).to have_attributes(expected_user_attributes)
      end

      it 'sends an email to the admins' do
        Sidekiq::Testing.inline! do
          expect { post_mutation }.to change(ActionMailer::Base.deliveries, :count).by(1)
        end
      end

      it "sets the user's signup provider to 'facebook'" do
        post_mutation
        user = User.last
        expect(user.signup_provider).to eq('facebook')
      end

      it 'returns the user' do
        post_mutation
        json = response.parsed_body
        data = json['data']['continueWithFacebook']

        expect(data['email']).to eq(email)
        expect(data['admin']).to be(false)
      end
    end

    context 'when the user exists' do
      before do
        create(:user, email: email)
      end

      it 'does not create a new user' do
        expect { post_mutation }.not_to change(User, :count)
      end

      it 'returns the user' do
        post_mutation
        json = response.parsed_body
        data = json['data']['continueWithFacebook']

        expect(data['email']).to eq(email)
        expect(data['admin']).to be(false)
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
