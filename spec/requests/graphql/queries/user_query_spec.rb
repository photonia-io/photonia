# frozen_string_literal: true

require 'rails_helper'

describe 'user Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let!(:target_user) { create(:user, email: 'target@example.com', first_name: 'Target', last_name: 'User', signup_provider: 'google') }

  let(:query) do
    <<~GQL
      query {
        user(id: "#{target_user.slug}") {
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

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls user' do
      post_query
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['user'])
      expect(json.dig('data', 'user')).to be_nil
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user, admin: false) }

      it 'returns NOT_FOUND error and nulls user' do
        post_query
        json = response.parsed_body
        err = json['errors']&.first

        expect(err).to be_present
        expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
        expect(err['path']).to eq(['user'])
        expect(json.dig('data', 'user')).to be_nil
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, admin: true) }

      it 'returns the requested user' do
        post_query

        json = JSON.parse(response.body)
        data = json['data']['user']

        expect(data).to include(
          'id' => target_user.slug,
          'email' => 'target@example.com',
          'firstName' => 'Target',
          'lastName' => 'User',
          'signupProvider' => 'google'
        )
      end

      context 'when the user does not exist' do
        let(:query) do
          <<~GQL
            query {
              user(id: "nonexistent") {
                id
                email
              }
            }
          GQL
        end

        it 'returns an error' do
          post_query
          json = response.parsed_body
          err = json['errors']&.first

          expect(err).to be_present
          expect(err['message']).to include('User not found')
        end
      end
    end
  end
end
