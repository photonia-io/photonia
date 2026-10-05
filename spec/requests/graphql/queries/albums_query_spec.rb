# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'albums Query' do
  include Devise::Test::IntegrationHelpers

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
            title
            photosCount
            coverPhoto {
              id
            }
          }
        }
      }
    GQL
  end

  describe 'paging' do
    subject(:post_query) { post '/graphql', params: { query: } }

    let(:album_count) { 3 }
    let(:albums) { create_list(:album, album_count) }
    let(:photo) { create(:photo) }

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

  describe 'ordering' do
    def public_album(title, **attrs)
      create(:album, title:, **attrs).tap do |album|
        album.photos << create(:photo)
        album.maintenance
      end
    end

    let!(:recent) { public_album('Recent', created_at: 2.days.ago) }
    let!(:backfilled) { public_album('Backfilled', created_at: 1.day.ago, sort_date: 5.years.ago.to_date) }

    it 'honours sort_date in paginated mode' do
      post '/graphql', params: { query: }

      titles = response.parsed_body.dig('data', 'albums', 'collection').pluck('title')
      expect(titles).to eq(%w[Recent Backfilled])
    end

    it 'honours sort_date in simple newest mode' do
      post '/graphql', params: { query: 'query { albums(mode: "simple", order: "newest") { collection { title } } }' }

      titles = response.parsed_body.dig('data', 'albums', 'collection').pluck('title')
      expect(titles).to eq(%w[Recent Backfilled])
    end
  end

  describe 'simple mode' do
    subject(:post_query) { post '/graphql', params: { query: } }

    let(:query) do
      <<~GQL
        query {
          albums(mode: "simple", query: "lake", limit: 5) {
            collection { id title }
          }
        }
      GQL
    end

    it 'filters by title prefix, ordered by title' do
      photo = create(:photo)
      matching = [create(:album, title: 'Lake trip'), create(:album, title: 'Lake house')]
      not_matching = create(:album, title: 'Mountains')
      [*matching, not_matching].each do |album|
        album.photos << photo
        album.maintenance
      end

      post_query

      titles = response.parsed_body.dig('data', 'albums', 'collection').map { |a| a['title'] }
      expect(titles).to eq(['Lake house', 'Lake trip'])
    end

    it 'returns the newest albums first when ordered by newest' do
      photo = create(:photo)
      albums = [create(:album, title: 'B old', created_at: 3.days.ago),
                create(:album, title: 'A newest', created_at: 1.day.ago),
                create(:album, title: 'C middle', created_at: 2.days.ago)]
      albums.each do |album|
        album.photos << photo
        album.maintenance
      end

      post '/graphql', params: {
        query: <<~GQL
          query {
            albums(mode: "simple", order: "newest", limit: 2) {
              collection { title }
            }
          }
        GQL
      }

      titles = response.parsed_body.dig('data', 'albums', 'collection').map { |a| a['title'] }
      expect(titles).to eq(['A newest', 'C middle'])
    end

    it 'hides a private album with no public photos from a visitor' do
      photo = create(:photo, privacy: 'private')
      album = create(:album, title: 'Lake trip', privacy: 'private')
      album.photos << photo
      album.maintenance

      post_query

      expect(response.parsed_body.dig('data', 'albums', 'collection')).to be_empty
    end
  end
end
