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
end
