# frozen_string_literal: true

require 'rails_helper'

describe 'cover photo and photo counts by role', :authorization do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: } }

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

  # Albums:
  let(:private_album_only_private_photos) { create(:album, user: owner, privacy: :private, sorting_type: :manual) }
  let(:public_album_only_private_photos)  { create(:album, user: owner, privacy: :public,  sorting_type: :manual) }
  let(:public_album_only_public_photos)   { create(:album, user: owner, privacy: :public,  sorting_type: :manual) }
  let(:public_album_mixed_photos)         { create(:album, user: owner, privacy: :public,  sorting_type: :manual) }

  # Photos for album1 (private album, only private photos; cover = one private photo)
  let!(:a1p1_private) { create(:photo, user: owner, privacy: :private) }
  let!(:a1p2_private) { create(:photo, user: owner, privacy: :private) }

  # Photos for album2 (public album, only private photos; cover = one private photo)
  let!(:a2p1_private) { create(:photo, user: owner, privacy: :private) }
  let!(:a2p2_private) { create(:photo, user: owner, privacy: :private) }

  # Photos for album3 (public album, only public photos; cover = one public photo)
  let!(:a3p1_public) { create(:photo, user: owner) }
  let!(:a3p2_public) { create(:photo, user: owner) }

  # Photos for album4 (public album, both private and public; cover = a private photo)
  let!(:a4p1_public)  { create(:photo, user: owner) }
  let!(:a4p2_private) { create(:photo, user: owner, privacy: :private) }
  let!(:a4p3_public)  { create(:photo, user: owner) }

  include_context 'with auth actors'

  before do
    # Album 1 setup
    private_album_only_private_photos.photos << [a1p1_private, a1p2_private]
    private_album_only_private_photos.update!(user_cover_photo_id: a1p1_private.id)
    private_album_only_private_photos.maintenance

    # Album 2 setup
    public_album_only_private_photos.photos << [a2p1_private, a2p2_private]
    public_album_only_private_photos.update!(user_cover_photo_id: a2p1_private.id)
    public_album_only_private_photos.maintenance

    # Album 3 setup (user cover is public => also becomes public cover)
    public_album_only_public_photos.photos << [a3p1_public, a3p2_public]
    public_album_only_public_photos.update!(user_cover_photo_id: a3p2_public.id)
    public_album_only_public_photos.maintenance

    # Album 4 setup (first public photo should be a4p1_public for visitors)
    public_album_mixed_photos.photos << [a4p1_public, a4p2_private, a4p3_public]
    public_album_mixed_photos.update!(user_cover_photo_id: a4p2_private.id)
    public_album_mixed_photos.maintenance
  end

  def albums_payload
    response.parsed_body['data']['albums']
  end

  def collection_map
    albums_payload['collection'].index_by { |a| a['id'] }
  end

  context 'when visitor is not logged in' do
    it 'includes only albums 3 and 4 with correct coverPhoto and photosCount' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].pluck('id')
      map  = collection_map

      expect(meta['totalCount']).to eq(2)
      expect(ids).to contain_exactly(public_album_only_public_photos.slug, public_album_mixed_photos.slug)

      # Album 3: cover is the user-set public photo
      expect(map[public_album_only_public_photos.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[public_album_only_public_photos.slug]['photosCount']).to eq(2)

      # Album 4: cover is the first public photo in the album
      expect(map[public_album_mixed_photos.slug]['coverPhoto']['id']).to eq(a4p1_public.slug)
      expect(map[public_album_mixed_photos.slug]['photosCount']).to eq(2)
    end
  end

  context 'when logged in as a non-owner' do
    before { sign_in(stranger) }

    it 'behaves the same as a visitor' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].pluck('id')
      map  = collection_map

      expect(meta['totalCount']).to eq(2)
      expect(ids).to contain_exactly(public_album_only_public_photos.slug, public_album_mixed_photos.slug)
      expect(map[public_album_only_public_photos.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[public_album_only_public_photos.slug]['photosCount']).to eq(2)
      expect(map[public_album_mixed_photos.slug]['coverPhoto']['id']).to eq(a4p1_public.slug)
      expect(map[public_album_mixed_photos.slug]['photosCount']).to eq(2)
    end
  end

  context 'when logged in as the owner' do
    before { sign_in(owner) }

    it 'includes all albums with user-set covers and total photo counts' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].pluck('id')
      map  = collection_map

      expect(meta['totalCount']).to eq(4)
      expect(ids).to contain_exactly(
        private_album_only_private_photos.slug,
        public_album_only_private_photos.slug,
        public_album_only_public_photos.slug,
        public_album_mixed_photos.slug
      )

      expect(map[private_album_only_private_photos.slug]['coverPhoto']['id']).to eq(a1p1_private.slug)
      expect(map[public_album_only_private_photos.slug]['coverPhoto']['id']).to eq(a2p1_private.slug)
      expect(map[public_album_only_public_photos.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[public_album_mixed_photos.slug]['coverPhoto']['id']).to eq(a4p2_private.slug)

      expect(map[private_album_only_private_photos.slug]['photosCount']).to eq(2)
      expect(map[public_album_only_private_photos.slug]['photosCount']).to eq(2)
      expect(map[public_album_only_public_photos.slug]['photosCount']).to eq(2)
      expect(map[public_album_mixed_photos.slug]['photosCount']).to eq(3)
    end
  end

  context 'when logged in as an admin' do
    before { sign_in(admin) }

    it 'behaves the same as the owner' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].pluck('id')
      map  = collection_map

      expect(meta['totalCount']).to eq(4)
      expect(ids).to contain_exactly(
        private_album_only_private_photos.slug,
        public_album_only_private_photos.slug,
        public_album_only_public_photos.slug,
        public_album_mixed_photos.slug
      )

      expect(map[private_album_only_private_photos.slug]['coverPhoto']['id']).to eq(a1p1_private.slug)
      expect(map[public_album_only_private_photos.slug]['coverPhoto']['id']).to eq(a2p1_private.slug)
      expect(map[public_album_only_public_photos.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[public_album_mixed_photos.slug]['coverPhoto']['id']).to eq(a4p2_private.slug)

      expect(map[private_album_only_private_photos.slug]['photosCount']).to eq(2)
      expect(map[public_album_only_private_photos.slug]['photosCount']).to eq(2)
      expect(map[public_album_only_public_photos.slug]['photosCount']).to eq(2)
      expect(map[public_album_mixed_photos.slug]['photosCount']).to eq(3)
    end
  end
end
