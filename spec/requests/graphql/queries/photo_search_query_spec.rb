# frozen_string_literal: true

require 'rails_helper'

describe 'photoSearch Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: } }

  include_context 'with auth actors'

  def query_for(filters:, page: 1)
    <<~GQL
      query {
        photoSearch(filters: #{filters}, page: #{page}) {
          collection { id }
          metadata { totalCount }
        }
      }
    GQL
  end

  describe 'privacy scoping' do
    let!(:private_photo) { create(:photo, user: owner, privacy: 'private', title: 'Private lake photo') }
    let(:query) { query_for(filters: '{ query: "lake" }') }

    it 'shows the owner their own private photo' do
      sign_in(owner)
      post_query

      ids = response.parsed_body.dig('data', 'photoSearch', 'collection').map { |p| p['id'] }
      expect(ids).to contain_exactly(private_photo.slug)
    end

    it 'hides a private photo from a stranger' do
      sign_in(stranger)
      post_query

      ids = response.parsed_body.dig('data', 'photoSearch', 'collection').map { |p| p['id'] }
      expect(ids).to be_empty
    end

    it 'hides a private photo from a visitor' do
      post_query

      ids = response.parsed_body.dig('data', 'photoSearch', 'collection').map { |p| p['id'] }
      expect(ids).to be_empty
    end
  end

  describe 'the privacy filter' do
    let!(:public_photo) { create(:photo, privacy: 'public') }
    let!(:private_photo) { create(:photo, user: owner, privacy: 'private') }
    let(:query) { query_for(filters: '{ privacy: PRIVATE }') }

    it 'returns only private photos for an admin' do
      sign_in(admin)
      post_query

      ids = response.parsed_body.dig('data', 'photoSearch', 'collection').map { |p| p['id'] }
      expect(ids).to contain_exactly(private_photo.slug)
    end

    it "cannot widen a stranger's visible set beyond their own photos" do
      sign_in(stranger)
      post_query

      ids = response.parsed_body.dig('data', 'photoSearch', 'collection').map { |p| p['id'] }
      expect(ids).to be_empty
    end
  end

  describe 'recording the search' do
    before { create(:photo, title: 'Lake photo') }

    it 'creates one search_queries row with the filters (excluding query) on page 1' do
      query = query_for(filters: '{ query: "lake", tags: ["sunset"] }')
      post '/graphql', params: { query: }

      expect(SearchQuery.count).to eq(1)
      search_query = SearchQuery.last
      expect(search_query.query).to eq('lake')
      # tagsMode defaults to ALL even when not explicitly set by the client
      expect(search_query.filters).to eq('tags' => ['sunset'], 'tags_mode' => 'all')
    end

    it 'does not create a row on page 2' do
      query = query_for(filters: '{ query: "lake" }', page: 2)
      post '/graphql', params: { query: }

      expect(SearchQuery.count).to eq(0)
    end
  end
end
