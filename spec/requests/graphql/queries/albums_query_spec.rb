# frozen_string_literal: true

require 'rails_helper'

describe 'albums Query' do
  describe 'paging' do
    subject(:post_query) { post '/graphql', params: { query: } }

    let(:album_count) { 3 }
    let(:albums) { create_list(:album, album_count) }
    let(:photo) { create(:photo) }
    let(:query) do
      <<~GQL
        query {
          albums(page: 1) {
            metadata {
              totalPages
              totalCount
              currentPage
              limitValue
            }
            collection {
              id
            }
          }
        }
      GQL
    end

    before do
      albums.each do |album|
        album.photos << photo
        album.maintenance
      end
    end

    it 'returns the correct metadata' do
      post_query

      expect(response.parsed_body['data']['albums']['metadata']).to include(
        'totalPages' => 1,
        'totalCount' => album_count,
        'currentPage' => 1,
        'limitValue' => 20
      )
    end

    it 'returns the correct number of albums' do
      post_query

      expect(response.parsed_body['data']['albums']['collection'].length).to eq(album_count)
    end
  end
end

describe 'visibility via policy scope' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: } }

  let(:query) do
    <<~GQL
      query {
        albums(page: 1) {
          metadata {
            totalPages
            totalCount
            currentPage
            limitValue
          }
          collection {
            id
          }
        }
      }
    GQL
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin_user) { create(:user, admin: true) }

  let!(:other_public_album_1) { create(:album, user: other_user) }
  let!(:other_public_album_2) { create(:album, user: other_user) }
  let!(:other_private_album) { create(:album, user: other_user, privacy: :private) }
  let!(:my_private_album) { create(:album, user: user, privacy: :private) }

  let!(:public_photo_a) { create(:photo, user: other_user) }
  let!(:public_photo_b) { create(:photo, user: other_user) }
  let!(:private_photo_other) { create(:photo, user: other_user, privacy: :private) }
  let!(:private_photo_mine) { create(:photo, user: user, privacy: :private) }

  before do
    # Ensure public albums have at least one public photo so they appear to visitors
    other_public_album_1.photos << public_photo_a
    other_public_album_2.photos << public_photo_b

    # Private albums receive only private photos
    other_private_album.photos << private_photo_other
    my_private_album.photos << private_photo_mine

    # Update cached counters and cover photos
    [other_public_album_1, other_public_album_2, other_private_album, my_private_album].each(&:maintenance)
  end

  context 'as a visitor' do
    it 'returns only public albums that have public photos' do
      post_query

      meta = response.parsed_body['data']['albums']['metadata']
      collection = response.parsed_body['data']['albums']['collection']

      expect(meta['totalCount']).to eq(2) # only the two public albums with public photos
      expect(collection.length).to eq(2)
      returned_ids = collection.map { |a| a['id'] }
      expect(returned_ids).to include(other_public_album_1.slug, other_public_album_2.slug)
      expect(returned_ids).not_to include(other_private_album.slug, my_private_album.slug)
    end
  end

  context 'as a logged-in user' do
    before { sign_in(user) }

    it "returns public albums plus the user's own albums regardless of privacy" do
      post_query

      meta = response.parsed_body['data']['albums']['metadata']
      collection = response.parsed_body['data']['albums']['collection']

      # public (2) + my_private_album (1) = 3
      expect(meta['totalCount']).to eq(3)
      expect(collection.length).to eq(3)
      returned_ids = collection.map { |a| a['id'] }
      expect(returned_ids).to include(other_public_album_1.slug, other_public_album_2.slug, my_private_album.slug)
      expect(returned_ids).not_to include(other_private_album.slug)
    end
  end

  context 'as an admin' do
    before { sign_in(admin_user) }

    it 'returns all albums regardless of privacy or public photos count' do
      post_query

      meta = response.parsed_body['data']['albums']['metadata']
      collection = response.parsed_body['data']['albums']['collection']

      # all 4 albums
      expect(meta['totalCount']).to eq(4)
      expect(collection.length).to eq(4)
      returned_ids = collection.map { |a| a['id'] }
      expect(returned_ids).to include(
        other_public_album_1.slug,
        other_public_album_2.slug,
        other_private_album.slug,
        my_private_album.slug
      )
    end
  end
end
