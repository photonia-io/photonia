# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'setAlbumCollapsedInFeed Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  include_context 'with auth actors'

  let(:album) { create(:album, user: owner, sorting_type: 'manual') }
  let(:collapsed) { true }

  let(:query) do
    <<~GQL
      mutation {
        setAlbumCollapsedInFeed(
          id: "#{album.slug}",
          collapsed: #{collapsed}
        ) {
          album {
            id
            collapsedInFeed
          }
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns the NOT_FOUND error and nulls the payload' do
      post_mutation
      json = response.parsed_body

      expect(json.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'setAlbumCollapsedInFeed')).to be_nil
    end
  end

  context 'when signed in as a stranger' do
    before { sign_in(stranger) }

    it 'returns the same NOT_FOUND error as a missing album' do
      post_mutation
      json = response.parsed_body

      expect(json.dig('errors', 0, 'extensions', 'code')).to eq('NOT_FOUND')
      expect(json.dig('data', 'setAlbumCollapsedInFeed')).to be_nil
    end
  end

  context 'when signed in as the owner' do
    before { sign_in(owner) }

    it 'collapses the album' do
      album.photos << create(:photo, user: owner, privacy: 'public')
      album.maintenance

      post_mutation
      data = data_dig(response, 'setAlbumCollapsedInFeed')

      expect(data['album']).to include('id' => album.slug, 'collapsedInFeed' => true)
      expect(album.reload.collapsed_in_feed).to be(true)
    end

    it 'rejects collapsing an album with no public photos' do
      post_mutation
      json = response.parsed_body

      expect(json['errors'].first['message']).to eq('Add at least one public photo before collapsing this album')
      expect(album.reload.collapsed_in_feed).to be(false)
    end

    it 'rejects collapsing an album whose photos were not posted consecutively' do
      now = Time.zone.now.change(usec: 0)
      first = create(:photo, user: owner, privacy: 'public', posted_at: now)
      create(:photo, posted_at: now + 30.minutes)
      last = create(:photo, user: owner, privacy: 'public', posted_at: now + 1.hour)
      album.photos << first
      album.photos << last
      album.maintenance

      post_mutation
      json = response.parsed_body

      expect(json['errors'].first['message']).to eq("Can't collapse: the photos of this album were not posted consecutively")
      expect(album.reload.collapsed_in_feed).to be(false)
    end

    it 'refreshes hidden_from_feed for the album photos' do
      cover = create(:photo, user: owner, privacy: 'public')
      other = create(:photo, user: owner, privacy: 'public')
      album.photos << cover
      album.photos << other
      album.maintenance

      post_mutation

      expect(cover.reload.hidden_from_feed).to be(false)
      expect(other.reload.hidden_from_feed).to be(true)
    end

    context 'when uncollapsing' do
      let(:collapsed) { false }

      before { album.update!(collapsed_in_feed: true) }

      it 'uncollapses the album and unhides its photos' do
        photo = create(:photo, user: owner, privacy: 'public')
        cover = create(:photo, user: owner, privacy: 'public')
        album.photos << cover
        album.photos << photo
        album.maintenance
        expect(photo.reload.hidden_from_feed).to be(true)

        post_mutation
        data = data_dig(response, 'setAlbumCollapsedInFeed')

        expect(data['album']).to include('collapsedInFeed' => false)
        expect(photo.reload.hidden_from_feed).to be(false)
      end
    end
  end

  context 'when signed in as an admin' do
    before { sign_in(admin) }

    it 'allows collapsing another user\'s album' do
      album.photos << create(:photo, user: owner, privacy: 'public')
      album.maintenance

      post_mutation
      data = data_dig(response, 'setAlbumCollapsedInFeed')

      expect(data['album']).to include('collapsedInFeed' => true)
    end
  end
end
