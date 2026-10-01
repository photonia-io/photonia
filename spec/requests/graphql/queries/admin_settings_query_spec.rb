# frozen_string_literal: true

require 'rails_helper'

describe 'adminSettings Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:site_name) { 'Photonia' }
  let(:site_description) { 'A photo gallery' }
  let(:site_tracking_code) { '<script>some_javascript_code</script>' }
  let(:continue_with_google_enabled) { true }
  let(:continue_with_facebook_enabled) { true }
  let(:rekognition_enabled) { true }
  let(:commenting_enabled) { true }
  let(:photo_commenting_enabled) { true }
  let(:album_commenting_enabled) { false }

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
          rekognitionEnabled
          commentingEnabled
          photoCommentingEnabled
          albumCommentingEnabled
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
    Setting.rekognition_enabled = rekognition_enabled
    Setting.commenting_enabled = commenting_enabled
    Setting.photo_commenting_enabled = photo_commenting_enabled
    Setting.album_commenting_enabled = album_commenting_enabled
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls adminSettings' do
      post_query
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['adminSettings'])
      expect(json.dig('data', 'adminSettings')).to be_nil
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(user)
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user, admin: false) }

      it 'returns NOT_FOUND error and nulls adminSettings' do
        post_query
        json = response.parsed_body
        err = json['errors']&.first

        expect(err).to be_present
        expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
        expect(err['path']).to eq(['adminSettings'])
        expect(json.dig('data', 'adminSettings')).to be_nil
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, admin: true) }

      describe 'homepage settings' do
        let(:query) do
          <<~GQL
            query {
              adminSettings {
                homepageStatsEnabled
                homepageTagsEnabled
                homepageSpotlightAlbumId
                spotlightAlbumChoices { id title }
              }
            }
          GQL
        end

        def public_album(title, privacy: 'public')
          create(:album, title:, privacy:).tap do |album|
            album.photos << create(:photo, privacy:)
            album.maintenance
          end
        end

        it 'returns the toggles (all on by default) and the album picker choices, by title' do
          zebra = public_album('Zebra')
          apple = public_album('Apple')
          public_album('Secret', privacy: 'private')
          Setting.homepage_tags_enabled = false

          post_query

          data = response.parsed_body.dig('data', 'adminSettings')
          expect(data).to include('homepageStatsEnabled' => true, 'homepageTagsEnabled' => false,
                                  'homepageSpotlightAlbumId' => '')
          expect(data['spotlightAlbumChoices']).to eq(
            [{ 'id' => apple.slug, 'title' => 'Apple' }, { 'id' => zebra.slug, 'title' => 'Zebra' }]
          )
        end
      end

      it 'returns admin settings' do
        post_query

        json = JSON.parse(response.body)
        data = json['data']['adminSettings']

        expect(data).to include(
          'id' => 'admin-settings',
          'siteName' => site_name,
          'siteDescription' => site_description,
          'siteTrackingCode' => site_tracking_code,
          'continueWithGoogleEnabled' => continue_with_google_enabled,
          'continueWithFacebookEnabled' => continue_with_facebook_enabled,
          'rekognitionEnabled' => rekognition_enabled,
          'commentingEnabled' => commenting_enabled,
          'photoCommentingEnabled' => photo_commenting_enabled,
          'albumCommentingEnabled' => album_commenting_enabled
        )
      end
    end
  end
end
