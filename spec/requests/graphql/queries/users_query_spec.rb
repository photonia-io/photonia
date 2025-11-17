# frozen_string_literal: true

require 'rails_helper'

describe 'users Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:query) do
    <<~GQL
      query {
        users {
          id
          email
          firstName
          lastName
          displayName
          signupProvider
          admin
        }
      }
    GQL
  end

  let!(:user1) { create(:user, email: 'user1@example.com', first_name: 'John', last_name: 'Doe', signup_provider: 'local') }
  let!(:user2) { create(:user, email: 'user2@example.com', first_name: 'Jane', last_name: 'Smith', signup_provider: 'google') }
  let!(:user3) { create(:user, email: 'user3@example.com', first_name: 'Bob', last_name: 'Johnson', signup_provider: 'facebook') }

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls users' do
      post_query
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['users'])
      expect(json.dig('data', 'users')).to be_nil
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user, admin: false) }

      it 'returns NOT_FOUND error and nulls users' do
        post_query
        json = response.parsed_body
        err = json['errors']&.first

        expect(err).to be_present
        expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
        expect(err['path']).to eq(['users'])
        expect(json.dig('data', 'users')).to be_nil
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, admin: true) }

      it 'returns all users' do
        post_query

        json = JSON.parse(response.body)
        data = json['data']['users']

        expect(data).to be_an(Array)
        expect(data.length).to be >= 3

        user_emails = data.map { |u| u['email'] }
        expect(user_emails).to include('user1@example.com', 'user2@example.com', 'user3@example.com')
      end

      it 'includes signup provider information' do
        post_query

        json = JSON.parse(response.body)
        data = json['data']['users']

        google_user = data.find { |u| u['email'] == 'user2@example.com' }
        expect(google_user['signupProvider']).to eq('google')

        facebook_user = data.find { |u| u['email'] == 'user3@example.com' }
        expect(facebook_user['signupProvider']).to eq('facebook')
      end
    end
  end
end
