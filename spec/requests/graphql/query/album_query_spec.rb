# frozen_string_literal: true

require 'rails_helper'

describe 'album Query' do
  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:album) { create(:album) }
  let!(:photos) { create_list(:photo, 3, albums: [album]) }

  let(:query) do
    <<~GQL
      query {
        album(id: "#{album.slug}") {
          id
          title
          descriptionHtml
          photos(page: 1) {
            collection {
              id
              title
              intelligentOrSquareMediumImageUrl: imageUrl(type: "intelligent_or_square_medium")
            }
            metadata {
              totalPages
              totalCount
              currentPage
              limitValue
            }
          }
        }
      }
    GQL
  end

  it 'returns the correct album' do
    post_query

    parsed_body = response.parsed_body
    response_album = parsed_body['data']['album']

    expect(response_album['id']).to eq(album.slug)
    expect(response_album['title']).to eq(album.title)
    expect(response_album['photos']['collection'].size).to eq(photos.size)
  end
end
