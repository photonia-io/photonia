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

  include_context 'auth actors'

  # Albums:
  let!(:album1) { create(:album, user: owner, privacy: :private, sorting_type: :manual) }
  let!(:album2) { create(:album, user: owner, privacy: :public,  sorting_type: :manual) }
  let!(:album3) { create(:album, user: owner, privacy: :public,  sorting_type: :manual) }
  let!(:album4) { create(:album, user: owner, privacy: :public,  sorting_type: :manual) }

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

  before do
    # Album 1 setup
    album1.photos << [a1p1_private, a1p2_private]
    album1.update!(user_cover_photo_id: a1p1_private.id)
    album1.maintenance

    # Album 2 setup
    album2.photos << [a2p1_private, a2p2_private]
    album2.update!(user_cover_photo_id: a2p1_private.id)
    album2.maintenance

    # Album 3 setup (user cover is public => also becomes public cover)
    album3.photos << [a3p1_public, a3p2_public]
    album3.update!(user_cover_photo_id: a3p2_public.id)
    album3.maintenance

    # Album 4 setup (first public photo should be a4p1_public for visitors)
    album4.photos << [a4p1_public, a4p2_private, a4p3_public]
    album4.update!(user_cover_photo_id: a4p2_private.id)
    album4.maintenance
  end

  def albums_payload
    response.parsed_body['data']['albums']
  end

  def collection_map
    albums_payload['collection'].index_by { |a| a['id'] }
  end

  context 'as a visitor (not logged in)' do
    it 'includes only albums 3 and 4 with correct coverPhoto and photosCount' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].map { |a| a['id'] }
      map  = collection_map

      expect(meta['totalCount']).to eq(2)
      expect(ids).to contain_exactly(album3.slug, album4.slug)

      # Album 3: cover is the user-set public photo
      expect(map[album3.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[album3.slug]['photosCount']).to eq(2)

      # Album 4: cover is the first public photo in the album
      expect(map[album4.slug]['coverPhoto']['id']).to eq(a4p1_public.slug)
      expect(map[album4.slug]['photosCount']).to eq(2)
    end
  end

  context 'as a logged-in non-owner' do
    before { sign_in(stranger) }

    it 'behaves the same as a visitor' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].map { |a| a['id'] }
      map  = collection_map

      expect(meta['totalCount']).to eq(2)
      expect(ids).to contain_exactly(album3.slug, album4.slug)
      expect(map[album3.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[album3.slug]['photosCount']).to eq(2)
      expect(map[album4.slug]['coverPhoto']['id']).to eq(a4p1_public.slug)
      expect(map[album4.slug]['photosCount']).to eq(2)
    end
  end

  context 'as the owner' do
    before { sign_in(owner) }

    it 'includes all albums with user-set covers and total photo counts' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].map { |a| a['id'] }
      map  = collection_map

      expect(meta['totalCount']).to eq(4)
      expect(ids).to contain_exactly(album1.slug, album2.slug, album3.slug, album4.slug)

      expect(map[album1.slug]['coverPhoto']['id']).to eq(a1p1_private.slug)
      expect(map[album2.slug]['coverPhoto']['id']).to eq(a2p1_private.slug)
      expect(map[album3.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[album4.slug]['coverPhoto']['id']).to eq(a4p2_private.slug)

      expect(map[album1.slug]['photosCount']).to eq(2)
      expect(map[album2.slug]['photosCount']).to eq(2)
      expect(map[album3.slug]['photosCount']).to eq(2)
      expect(map[album4.slug]['photosCount']).to eq(3)
    end
  end

  context 'as an admin' do
    before { sign_in(admin) }

    it 'behaves the same as the owner' do
      post_query

      meta = albums_payload['metadata']
      ids  = albums_payload['collection'].map { |a| a['id'] }
      map  = collection_map

      expect(meta['totalCount']).to eq(4)
      expect(ids).to contain_exactly(album1.slug, album2.slug, album3.slug, album4.slug)

      expect(map[album1.slug]['coverPhoto']['id']).to eq(a1p1_private.slug)
      expect(map[album2.slug]['coverPhoto']['id']).to eq(a2p1_private.slug)
      expect(map[album3.slug]['coverPhoto']['id']).to eq(a3p2_public.slug)
      expect(map[album4.slug]['coverPhoto']['id']).to eq(a4p2_private.slug)

      expect(map[album1.slug]['photosCount']).to eq(2)
      expect(map[album2.slug]['photosCount']).to eq(2)
      expect(map[album3.slug]['photosCount']).to eq(2)
      expect(map[album4.slug]['photosCount']).to eq(3)
    end
  end
end
