# frozen_string_literal: true

require 'rails_helper'

describe 'userSettings Query' do
  include Devise::Test::IntegrationHelpers

  let(:email) { Faker::Internet.email }
  let(:first_name) { Faker::Name.first_name }
  let(:last_name) { Faker::Name.last_name }
  let(:display_name) { Faker::Name.name }
  let(:timezone) { ActiveSupport::TimeZone.all.sample.name }

  let(:query) do
    <<~GQL
      query {
        userSettings {
          id
          email
          firstName
          lastName
          displayName
          timezone {
            name
          }
          admin
          uploader
        }
      }
    GQL
  end

  subject(:post_query) { post '/graphql', params: { query: query } }

  context 'when the user is not logged in' do
    it 'returns an error message in the GraphQL response' do
      post_query

      json = JSON.parse(response.body)

      expect(json['errors'][0]).to include(
        'message' => 'User not signed in'
      )
    end
  end

  context 'when the user is logged in' do
    def sign_in_and_post_query(user)
      sign_in(user)
      post_query
    end

    context 'and is a registered user' do
      let!(:user) { create(:user, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone) }

      before do
        sign_in_and_post_query(user)
      end

      it_behaves_like 'user settings', admin: false, uploader: false
    end

    context 'and is an uploader' do
      let!(:user) { create(:user, :uploader, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone) }

      before do
        sign_in_and_post_query(user)
      end

      it_behaves_like 'user settings', admin: false, uploader: true
    end

    context 'and is an admin' do
      let!(:user) { create(:user, admin: true, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone) }

      before do
        sign_in_and_post_query(user)
      end

      it_behaves_like 'user settings', admin: true, uploader: true
    end
  end
end
