# frozen_string_literal: true

require 'rails_helper'

describe 'updateAdminSettings Mutation (homepage)', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: } }

  let(:admin) { create(:user, admin: true) }
  let(:query) do
    <<~GQL
      mutation {
        updateAdminSettings(#{arguments}) {
          homepageStatsEnabled
          homepageRandomEnabled
          homepageSpotlightAlbumId
        }
      }
    GQL
  end

  def public_album(title: 'Lake trip')
    create(:album, title:).tap do |album|
      album.photos << create(:photo)
      album.maintenance
    end
  end

  before { sign_in(admin) }

  context 'when toggling sections' do
    let(:arguments) { 'homepageStatsEnabled: false, homepageRandomEnabled: false' }

    it 'saves them and leaves the other sections alone' do
      post_mutation

      expect(response.parsed_body.dig('data', 'updateAdminSettings'))
        .to include('homepageStatsEnabled' => false, 'homepageRandomEnabled' => false)
      expect(Setting.homepage_sections).to include(stats: false, random: false, tags: true, years: true)
    end
  end

  context 'when picking a spotlight album' do
    let(:album) { public_album }
    let(:arguments) { %(homepageSpotlightAlbumId: "#{album.slug}") }

    it 'stores its slug' do
      post_mutation

      expect(Setting.homepage_spotlight_album_id).to eq(album.slug)
    end
  end

  context 'when clearing the spotlight album' do
    let(:arguments) { 'homepageSpotlightAlbumId: ""' }

    before { Setting.homepage_spotlight_album_id = 'something' }

    it 'resets to the latest-album default' do
      post_mutation

      expect(Setting.homepage_spotlight_album_id).to eq('')
    end
  end

  context 'when the spotlight album is private or unknown' do
    let(:arguments) { %(homepageSpotlightAlbumId: "#{slug}") }
    let(:private_album) do
      create(:album, privacy: 'private').tap do |album|
        album.photos << create(:photo, privacy: 'private')
        album.maintenance
      end
    end

    %w[private unknown].each do |kind|
      context "with a #{kind} album" do
        let(:slug) { kind == 'private' ? private_album.slug : 'no-such-album' }

        it 'is rejected and nothing changes' do
          post_mutation

          expect(response.parsed_body['errors'].first['message']).to include('public album')
          expect(Setting.homepage_spotlight_album_id).to eq('')
        end
      end
    end
  end

  context 'when the user is not an admin' do
    let(:admin) { create(:user, admin: false) }
    let(:arguments) { 'homepageStatsEnabled: false' }

    it 'is denied and changes nothing' do
      post_mutation

      expect(response.parsed_body['errors'].first.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(Setting.homepage_stats_enabled).to be(true)
    end
  end
end
