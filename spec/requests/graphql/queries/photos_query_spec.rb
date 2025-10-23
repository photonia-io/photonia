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

    before do
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

    context 'when there is a limit parameter' do
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
      let(:query) do
        <<~GQL
          query {
            photos(mode: "simple", limit: 150) {
              collection {
                id
              }
            }
          }
        GQL
      end

      it 'enforces the maximum limit of 100 by applying .limit(100) to the relation' do
        relation = double('relation')
        # Return a small stubbed list so the test stays cheap
        fake_photos = build_stubbed_list(:photo, 3)

        allow(Photo).to receive(:order).and_return(relation)
        expect(relation).to receive(:limit).with(100).and_return(fake_photos)

        post '/graphql', params: { query: }

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(fake_photos.length)
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

      it 'applies the default maximum limit of 100 by calling .limit(100) on the relation' do
        relation = double('relation')
        # Return a small stubbed list so the test stays cheap
        fake_photos = build_stubbed_list(:photo, 3)

        allow(Photo).to receive(:order).and_return(relation)
        expect(relation).to receive(:limit).with(100).and_return(fake_photos)

        post '/graphql', params: { query: }

        expect(response.parsed_body['data']['photos']['collection'].length).to eq(fake_photos.length)
      end
    end
  end
end
