# frozen_string_literal: true

require 'rails_helper'

describe 'userSettings Query' do
  include Devise::Test::IntegrationHelpers

  let(:email) { Faker::Internet.email }
  let(:first_name) { Faker::Name.first_name }
  let(:last_name) { Faker::Name.last_name }
  let(:display_name) { Faker::Name.name }
  let(:timezone) { ActiveSupport::TimeZone.all.sample.name }

  let!(:user) { create(:user, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone) }

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
        }
      }
    GQL
  end

  subject(:post_query) { post '/graphql', params: { query: query } }

  context 'when the user is not logged in' do
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_query }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    it 'returns the user settings' do
      post_query

      json = JSON.parse(response.body)
      data = json['data']['userSettings']

      expect(data).to include(
        'id' => user.slug,
        'email' => email,
        'firstName' => first_name,
        'lastName' => last_name,
        'displayName' => display_name,
        'timezone' => { 'name' => timezone }
      )
    end
  end
end
