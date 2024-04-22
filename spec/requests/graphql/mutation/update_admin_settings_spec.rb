# frozen_string_literal: true

require 'rails_helper'

describe 'updateAdminSettings Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:site_name) { 'Photonia' }
  let(:site_description) { 'A photo gallery' }
  let(:site_tracking_code) { '<script>some_javascript_code</script>' }

  let(:new_site_name) { 'New Photonia' }
  let(:new_site_description) { 'A new photo gallery' }
  let(:new_site_tracking_code) { '<script>new_javascript_code</script>' }

  let(:query) do
    <<~GQL
      mutation {
        updateAdminSettings(
          siteName: "#{new_site_name}"
          siteDescription: "#{new_site_description}"
          siteTrackingCode: "#{new_site_tracking_code}"
        ) {
          siteName
          siteDescription
          siteTrackingCode
        }
      }
    GQL
  end

  before do
    Setting.site_name = site_name
    Setting.site_description = site_description
    Setting.site_tracking_code = site_tracking_code
  end

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  context 'when the user is not logged in' do
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user, admin: false) }

      it 'raises Pundit::NotAuthorizedError' do
        expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, admin: true) }

      it 'updates admin settings' do
        post_mutation

        json = JSON.parse(response.body)
        data = json['data']['updateAdminSettings']

        expect(data).to include(
          'siteName' => new_site_name,
          'siteDescription' => new_site_description,
          'siteTrackingCode' => new_site_tracking_code
        )

        expect(Setting.site_name).to eq(new_site_name)
        expect(Setting.site_description).to eq(new_site_description)
        expect(Setting.site_tracking_code).to eq(new_site_tracking_code)
      end
    end
  end
end
