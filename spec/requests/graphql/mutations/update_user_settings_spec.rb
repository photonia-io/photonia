# frozen_string_literal: true

require 'rails_helper'

describe 'updateUserSettings Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

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

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls updateUserSettings' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['updateUserSettings'])
      expect(json.dig('data', 'updateUserSettings')).to be_nil
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

    context 'when defaultLicense is omitted from the query' do
      let!(:user) { create(:user, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone, default_license: 'CC BY 4.0') }

      it 'leaves the existing default license untouched' do
        post_mutation
        expect(user.reload.default_license).to eq('CC BY 4.0')
      end
    end

    context 'when defaultLicense is provided' do
      let(:default_license_arg) { '"CC0 1.0"' }
      let(:query) do
        <<~GQL
          mutation {
            updateUserSettings(
              email: "#{new_email}"
              firstName: "#{new_first_name}"
              lastName: "#{new_last_name}"
              displayName: "#{new_display_name}"
              timezone: "#{new_timezone}"
              defaultLicense: #{default_license_arg}
            ) {
              id
              defaultLicense
            }
          }
        GQL
      end

      it 'updates the default license' do
        post_mutation
        expect(user.reload.default_license).to eq('CC0 1.0')
      end
    end

    context 'when defaultLicense is provided as an empty string' do
      let!(:user) { create(:user, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone, default_license: 'CC BY 4.0') }
      let(:default_license_arg) { '""' }
      let(:query) do
        <<~GQL
          mutation {
            updateUserSettings(
              email: "#{new_email}"
              firstName: "#{new_first_name}"
              lastName: "#{new_last_name}"
              displayName: "#{new_display_name}"
              timezone: "#{new_timezone}"
              defaultLicense: #{default_license_arg}
            ) {
              id
              defaultLicense
            }
          }
        GQL
      end

      it 'clears the default license' do
        post_mutation
        expect(user.reload.default_license).to be_nil
      end
    end

    context 'when defaultLicense is invalid' do
      let!(:user) { create(:user, email: email, first_name: first_name, last_name: last_name, display_name: display_name, timezone: timezone, default_license: 'CC BY 4.0') }
      let(:default_license_arg) { '"Whatever I Want"' }
      let(:query) do
        <<~GQL
          mutation {
            updateUserSettings(
              email: "#{new_email}"
              firstName: "#{new_first_name}"
              lastName: "#{new_last_name}"
              displayName: "#{new_display_name}"
              timezone: "#{new_timezone}"
              defaultLicense: #{default_license_arg}
            ) {
              id
              defaultLicense
            }
          }
        GQL
      end

      it 'returns a validation error and saves none of the settings' do
        post_mutation
        json = response.parsed_body
        errors = json['errors'].first

        expect(errors['message']).to eq('Invalid license value')
        user.reload
        expect(user.default_license).to eq('CC BY 4.0')
        expect(user.first_name).to eq(first_name)
        expect(user.timezone).to eq(timezone)
      end
    end
  end
end
