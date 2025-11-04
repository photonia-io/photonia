# frozen_string_literal: true

# Shared examples for authorization-related expectations in GraphQL query specs.
#
# Assumptions:
# - The including spec defines `subject(:post_query)` which performs the GraphQL request.
# - The including spec defines `public_photo` and `private_photo` where applicable.
#
# Usage:
#   include_examples 'lists only public photos'
#   include_examples 'lists both public and private photos'

RSpec.shared_examples 'lists only public photos' do
  # Ensure records exist before issuing the GraphQL query
  before do
    public_photo
    private_photo
  end

  it 'lists only public photos' do
    post_query

    meta = response.parsed_body['data']['photos']['metadata']
    collection = response.parsed_body['data']['photos']['collection']
    ids = collection.pluck('id')

    expect(meta['totalCount']).to eq(1)
    expect(ids).to include(public_photo.slug)
    expect(ids).not_to include(private_photo.slug)
  end
end

RSpec.shared_examples 'lists both public and private photos' do
  # Ensure records exist before issuing the GraphQL query
  before do
    public_photo
    private_photo
  end

  it 'lists both public and private photos' do
    post_query

    meta = response.parsed_body['data']['photos']['metadata']
    collection = response.parsed_body['data']['photos']['collection']
    ids = collection.pluck('id')

    expect(meta['totalCount']).to eq(2)
    expect(ids).to include(public_photo.slug, private_photo.slug)
  end
end
