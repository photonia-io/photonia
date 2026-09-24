# frozen_string_literal: true

require 'rails_helper'

describe 'users Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:page) { 1 }
  let(:query) do
    <<~GQL
      query {
        users(page: #{page}) {
          collection {
            id
            email
            firstName
            lastName
            displayName
            signupProvider
            admin
          }
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
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
        data = data_dig(response, 'users', 'collection')

        expect(data).to be_an(Array)
        expect(data.length).to eq(4)

        user_emails = data.map { |u| u['email'] }
        expect(user_emails).to include('user1@example.com', 'user2@example.com', 'user3@example.com')
      end

      it 'includes signup provider information' do
        post_query
        data = data_dig(response, 'users', 'collection')

        google_user = data.find { |u| u['email'] == 'user2@example.com' }
        expect(google_user['signupProvider']).to eq('google')

        facebook_user = data.find { |u| u['email'] == 'user3@example.com' }
        expect(facebook_user['signupProvider']).to eq('facebook')
      end

      it 'returns pagination metadata' do
        post_query

        expect(data_dig(response, 'users', 'metadata')).to eq(
          'totalPages' => 1,
          'totalCount' => 4,
          'currentPage' => 1,
          'limitValue' => 20
        )
      end

      context 'when there are more users than fit on a page' do
        let(:page) { 2 }

        before { create_list(:user, 17) }

        it 'returns the overflow on the second page' do
          post_query

          expect(data_dig(response, 'users', 'collection').length).to eq(1)
          expect(data_dig(response, 'users', 'metadata')).to include(
            'totalPages' => 2,
            'totalCount' => 21,
            'currentPage' => 2
          )
        end
      end
    end
  end
end
