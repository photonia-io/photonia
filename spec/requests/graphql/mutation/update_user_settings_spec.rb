# frozen_string_literal: true

require 'rails_helper'

describe 'updateUserSettings Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:email) { 'test@test.com' }
  let(:first_name) { 'Test' }
  let(:last_name) { 'User' }
  let(:display_name) { 'Test User' }
  let(:timezone) { 'America/New_York' }

  let!(:user) { create(:user, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone) }

  let(:new_email) { 'newtest@test.com' }
  let(:new_first_name) { 'New Test' }
  let(:new_last_name) { 'New User' }
  let(:new_display_name) { 'New Test User' }
  let(:new_timezone) { 'America/Los_Angeles' }

  let(:query) do
    <<~GQL
      mutation {
        updateUserSettings(
          email: "#{new_email}"
          firstName: "#{new_first_name}"
          lastName: "#{new_last_name}"
          displayName: "#{new_display_name}"
          timezone: "#{new_timezone}"
        ) {
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

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  context 'when the user is not logged in' do
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError, 'User not signed in')
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    it 'updates the user settings' do
      post_mutation

      user.reload

      expect(user.email).to eq(email)
      expect(user.first_name).to eq(new_first_name)
      expect(user.last_name).to eq(new_last_name)
      expect(user.display_name).to eq(new_display_name)
      expect(user.timezone).to eq(new_timezone)
    end

    it 'returns the updated user settings' do
      post_mutation
      json = JSON.parse(response.body)
      data = json['data']['updateUserSettings']

      expect(data).to include(
        'id' => user.slug,
        'email' => email,
        'firstName' => new_first_name,
        'lastName' => new_last_name,
        'displayName' => new_display_name,
        'timezone' => { 'name' => new_timezone }
      )
    end
  end
end
