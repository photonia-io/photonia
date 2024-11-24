# frozen_string_literal: true

require 'rails_helper'

describe 'adminSettings Query' do
  include Devise::Test::IntegrationHelpers

  let(:site_name) { 'Photonia' }
  let(:site_description) { 'A photo gallery' }
  let(:site_tracking_code) { '<script>some_javascript_code</script>' }
  let(:continue_with_google_enabled) { true }
  let(:continue_with_facebook_enabled) { true }

  let(:query) do
    <<~GQL
      query {
        adminSettings {
          id
          siteName
          siteDescription
          siteTrackingCode
          continueWithGoogleEnabled
          continueWithFacebookEnabled
        }
      }
    GQL
  end

  before do
    Setting.site_name = site_name
    Setting.site_description = site_description
    Setting.site_tracking_code = site_tracking_code
    Setting.continue_with_google_enabled = continue_with_google_enabled
    Setting.continue_with_facebook_enabled = continue_with_facebook_enabled
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

    context 'when the user is not an admin' do
      let(:user) { create(:user, admin: false) }

      it 'raises Pundit::NotAuthorizedError' do
        expect { post_query }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, admin: true) }

      it 'returns admin settings' do
        post_query

        json = JSON.parse(response.body)
        data = json['data']['adminSettings']

        expect(data).to include(
          "id" => "admin-settings",
          "siteName" => site_name,
          "siteDescription" => site_description,
          "siteTrackingCode" => site_tracking_code,
          "continueWithGoogleEnabled" => continue_with_google_enabled,
          "continueWithFacebookEnabled" => continue_with_facebook_enabled
        )
      end
    end
  end
end
