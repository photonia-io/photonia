# frozen_string_literal: true

require 'rails_helper'

describe 'photos Query' do
  context 'when using the paginated mode' do
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

  context 'when using the simple mode' do
    subject(:post_query) { post '/graphql', params: { query: } }

    let(:photo_count) { 3 }

    # Set a lower SIMPLE_MODE_MAX_LIMIT for tests to avoid creating many records
    before do
      stub_const('Queries::PhotosQuery::SIMPLE_MODE_MAX_LIMIT', 5)
      create_list(:photo, 3)
    end

    context 'when there are no parameters' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple") {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'returns all photos' do
        post_query

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(photo_count)
      end
    end

    context 'when there is a limit parameter (and is below the maximum allowed limit)' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", limit: 2) {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'returns the correct number of photos' do
        post_query

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(2)
      end
    end

    context 'when fetchType is random' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", fetchType: "random") {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'returns the correct number of photos' do
        post_query

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(photo_count)
      end
    end

    context 'when limit exceeds maximum allowed limit' do
      # We're requesting 6 photos because for tests the SIMPLE_MODE_MAX_LIMIT is set 5
      # Normally SIMPLE_MODE_MAX_LIMIT is 100
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", limit: 6) {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'enforces the maximum limit of 5 (configured for tests)' do
        # Create 6 photos to test the limit enforcement (SIMPLE_MODE_MAX_LIMIT is 5 in tests)
        create_list(:photo, 6)

        post '/graphql', params: { query: }

        # Should return exactly 5 photos even though 6 was requested
        expect(response.parsed_body['data']['photos']['collection'].length).to eq(5)
      end
    end

    context 'when no limit is specified' do
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple") {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'applies the default maximum limit of 5 (configured for tests)' do
        # Create 6 photos to test the default limit (SIMPLE_MODE_MAX_LIMIT is 5 in tests)
        create_list(:photo, 6)

        post '/graphql', params: { query: }

        # Should return exactly 5 photos by default
        expect(response.parsed_body['data']['photos']['collection'].length).to eq(5)
      end
    end
  end
end
