# frozen_string_literal: true

require 'rails_helper'

describe 'album visibility and cover photo by role (single album query)', :authorization do
  include Devise::Test::IntegrationHelpers

  # Build a minimal query focused on photos and isCoverPhoto flags
  def query_for(id)
    <<~GQL
      query {
        album(id: "#{id}") {
          id
          photos {
            collection {
              id
              isCoverPhoto
            }
            metadata {
              totalCount
            }
          }
        }
      }
    GQL
  end

  # Albums and users
  include_context 'with auth actors'

  # 1) Private album with only private photos; user set cover is a private photo
  let(:private_album_only_private_photos) { create(:album, user: owner, privacy: :private, sorting_type: :manual) }
  let!(:a1p1_private) { create(:photo, user: owner, privacy: :private) }
  let!(:a1p2_private) { create(:photo, user: owner, privacy: :private) }

  # 2) Public album with only private photos; user set cover is a private photo
  let(:public_album_only_private_photos) { create(:album, user: owner, privacy: :public, sorting_type: :manual) }
  let!(:a2p1_private) { create(:photo, user: owner, privacy: :private) }
  let!(:a2p2_private) { create(:photo, user: owner, privacy: :private) }

  # 3) Public album with only public photos; user set cover is a public photo
  let(:public_album_only_public_photos) { create(:album, user: owner, privacy: :public, sorting_type: :manual) }
  let!(:a3p1_public) { create(:photo, user: owner) }
  let!(:a3p2_public) { create(:photo, user: owner) }

  # 4) Public album with both private and public photos; user set cover is a private photo
  let(:public_album_mixed_photos) { create(:album, user: owner, privacy: :public, sorting_type: :manual) }
  let!(:a4p1_public)  { create(:photo, user: owner) }
  let!(:a4p2_private) { create(:photo, user: owner, privacy: :private) }
  let!(:a4p3_public)  { create(:photo, user: owner) }

  before do
    # Album 1
    private_album_only_private_photos.photos << [a1p1_private, a1p2_private]
    private_album_only_private_photos.update!(user_cover_photo_id: a1p1_private.id)
    private_album_only_private_photos.maintenance

    # Album 2
    public_album_only_private_photos.photos << [a2p1_private, a2p2_private]
    public_album_only_private_photos.update!(user_cover_photo_id: a2p1_private.id)
    public_album_only_private_photos.maintenance

    # Album 3 (user cover is public => becomes public cover too)
    public_album_only_public_photos.photos << [a3p1_public, a3p2_public]
    public_album_only_public_photos.update!(user_cover_photo_id: a3p2_public.id)
    public_album_only_public_photos.maintenance

    # Album 4 (first public photo should be a4p1_public for visitors)
    public_album_mixed_photos.photos << [a4p1_public, a4p2_private, a4p3_public]
    public_album_mixed_photos.update!(user_cover_photo_id: a4p2_private.id)
    public_album_mixed_photos.maintenance
  end

  def post_album(id)
    post '/graphql', params: { query: query_for(id) }
    response.parsed_body
  end

  def collection_map(parsed_body)
    (parsed_body.dig('data', 'album', 'photos', 'collection') || []).index_by { |p| p['id'] }
  end

  context 'when visitor is not logged in' do
    it 'album one returns a NOT_FOUND error and nulls the album' do
      parsed = post_album(private_album_only_private_photos.slug)
      err = parsed['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['album'])
      expect(parsed.dig('data', 'album')).to be_nil
    end

    it 'album two returns an album without photos' do
      parsed = post_album(public_album_only_private_photos.slug)
      expect(parsed['errors']).to be_nil.or be_empty
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_private_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(0)
      expect(parsed.dig('data', 'album', 'photos', 'collection')).to eq([])
    end

    it "album three returns all photos (they're public) and isCoverPhoto is true for the user-set public cover" do
      parsed = post_album(public_album_only_public_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_public_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      # user-set cover is a3p2_public and should also be the public cover
      expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
    end

    it 'album four returns only public photos and isCoverPhoto is true for the first public photo' do
      parsed = post_album(public_album_mixed_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_mixed_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      # first public photo in insertion order is a4p1_public
      expect(map[a4p1_public.slug]['isCoverPhoto']).to be(true)
      # ensure private cover is not visible nor flagged (private photo not in collection)
      expect(map[a4p2_private.slug]).to be_nil
    end
  end

  context 'when logged in as a non-owner' do
    before { sign_in(stranger) }

    it 'behaves the same as a visitor for album one (NOT_FOUND error and null album)' do
      parsed = post_album(private_album_only_private_photos.slug)
      err = parsed['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['album'])
      expect(parsed.dig('data', 'album')).to be_nil
    end

    it 'behaves the same as a visitor for album two (no photos)' do
      parsed = post_album(public_album_only_private_photos.slug)
      expect(parsed['errors']).to be_nil.or be_empty
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_private_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(0)
      expect(parsed.dig('data', 'album', 'photos', 'collection')).to eq([])
    end

    it 'behaves the same as a visitor for album three (public cover photo flagged)' do
      parsed = post_album(public_album_only_public_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_public_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
    end

    it 'behaves the same as a visitor for album four (first public photo flagged)' do
      parsed = post_album(public_album_mixed_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_mixed_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a4p1_public.slug]['isCoverPhoto']).to be(true)
      expect(map[a4p2_private.slug]).to be_nil
    end
  end

  context 'when logged in as the owner' do
    before { sign_in(owner) }

    it 'album one returns all photos; user-set cover flagged' do
      parsed = post_album(private_album_only_private_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(private_album_only_private_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a1p1_private.slug]['isCoverPhoto']).to be(true)
    end

    it 'album two returns all photos; user-set cover flagged' do
      parsed = post_album(public_album_only_private_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_private_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a2p1_private.slug]['isCoverPhoto']).to be(true)
    end

    it 'album three returns all photos; user-set (public) cover flagged' do
      parsed = post_album(public_album_only_public_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_public_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
    end

    it 'album four returns all photos; user-set (private) cover flagged' do
      parsed = post_album(public_album_mixed_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_mixed_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(3)
      expect(map[a4p2_private.slug]['isCoverPhoto']).to be(true)
    end
  end

  context 'when logged in as an admin' do
    before { sign_in(admin) }

    it 'album one returns all photos; user-set cover flagged' do
      parsed = post_album(private_album_only_private_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(private_album_only_private_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a1p1_private.slug]['isCoverPhoto']).to be(true)
    end

    it 'album two returns all photos; user-set cover flagged' do
      parsed = post_album(public_album_only_private_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_private_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a2p1_private.slug]['isCoverPhoto']).to be(true)
    end

    it 'album three returns all photos; user-set (public) cover flagged' do
      parsed = post_album(public_album_only_public_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_only_public_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
      expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
    end

    it 'album four returns all photos; user-set (private) cover flagged' do
      parsed = post_album(public_album_mixed_photos.slug)
      map = collection_map(parsed)
      expect(parsed.dig('data', 'album', 'id')).to eq(public_album_mixed_photos.slug)
      expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(3)
      expect(map[a4p2_private.slug]['isCoverPhoto']).to be(true)
    end
  end
end
