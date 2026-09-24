# frozen_string_literal: true

require 'rails_helper'

describe 'photosByIds Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  include_context 'with auth actors'

  let(:query) do
    <<~GQL
      query {
        photosByIds(ids: #{ids_literal}) {
          id
          processed
        }
      }
    GQL
  end

  let(:public_photo) { create(:photo, privacy: :public, processed_at: Time.current) }
  let(:owner_private_photo) { create(:photo, user: owner, privacy: :private) }
  let(:stranger_private_photo) { create(:photo, user: stranger, privacy: :private) }
  let(:unprocessed_photo) { create(:photo, privacy: :public, processed_at: nil) }

  let(:ids_literal) do
    [public_photo, owner_private_photo, stranger_private_photo, unprocessed_photo]
      .map { |p| "\"#{p.slug}\"" }.join(', ').prepend('[').concat(']')
  end

  before do
    public_photo
    owner_private_photo
    stranger_private_photo
    unprocessed_photo
  end

  def returned_ids
    data_dig(response, 'photosByIds').pluck('id')
  end

  context 'when signed in as a visitor (not authenticated)' do
    it 'returns only public photos' do
      post_query
      expect(returned_ids).to contain_exactly(public_photo.slug, unprocessed_photo.slug)
    end
  end

  context 'when signed in as the owner' do
    before { sign_in(owner) }

    it "returns public photos plus the owner's own private photo" do
      post_query
      expect(returned_ids).to contain_exactly(public_photo.slug, unprocessed_photo.slug, owner_private_photo.slug)
    end
  end

  context 'when signed in as an admin' do
    before { sign_in(admin) }

    it 'returns every requested photo' do
      post_query
      expect(returned_ids).to contain_exactly(public_photo.slug, unprocessed_photo.slug, owner_private_photo.slug, stranger_private_photo.slug)
    end
  end

  context 'with an unknown slug mixed in' do
    let(:ids_literal) { "[\"#{public_photo.slug}\", \"does-not-exist\"]" }

    it 'silently omits it' do
      post_query
      expect(returned_ids).to eq([public_photo.slug])
    end
  end

  it 'reports the processed flag per photo' do
    sign_in(admin)
    post_query

    by_id = data_dig(response, 'photosByIds').index_by { |p| p['id'] }
    expect(by_id[public_photo.slug]['processed']).to be(true)
    expect(by_id[unprocessed_photo.slug]['processed']).to be(false)
  end

  it 'does not record an impression' do
    expect { post_query }.not_to(change { public_photo.reload.impressions_count })
  end
end
