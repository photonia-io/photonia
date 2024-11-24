# frozen_string_literal: true

require 'rails_helper'

describe 'tag Query' do
  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:tag) { create(:tag) }
  let!(:photos) { create_list(:photo, 3, tags: [tag]) }

  let(:query) do
    <<~GQL
      query {
        tag(id: "#{tag.slug}") {
          id
          name
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

  it 'returns the correct tag and records an impression' do
    expect { post_query }.to change { tag.reload.impressions_count }.by(1)

    parsed_body = response.parsed_body
    response_tag = parsed_body['data']['tag']

    expect(response_tag['id']).to eq(tag.slug)
    expect(response_tag['name']).to eq(tag.name)
    expect(response_tag['photos']['collection'].size).to eq(photos.size)
  end
end
