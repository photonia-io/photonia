# frozen_string_literal: true

require 'rails_helper'

describe 'photos Query' do
  describe 'paging' do
    subject(:post_query) { post '/graphql', params: { query: } }

    let(:photo_count) { 3 }
    let(:query) do
      <<~GQL
        query {
          photos(page: 1) {
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
      create_list(:photo, photo_count)
    end

    it 'returns the correct metadata' do
      post_query

      expect(response.parsed_body['data']['photos']['metadata']).to include(
        'totalPages' => 1,
        'totalCount' => photo_count,
        'currentPage' => 1,
        'limitValue' => 20
      )
    end

    it 'returns the correct number of photos' do
      post_query

      expect(response.parsed_body['data']['photos']['collection'].length).to eq(photo_count)
    end
  end
end
