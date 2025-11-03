# frozen_string_literal: true

require 'rails_helper'

describe 'album Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:user) { create(:user) }
  let(:album) { create(:album, user: user) }
  let(:public_photo_count) { 3 }
  let(:private_photo_count) { 1 }
  let!(:public_photos) { create_list(:photo, public_photo_count, albums: [album]) }
  let!(:private_photos) { create_list(:photo, private_photo_count, albums: [album], privacy: :private) }
  let(:first_public_photo) { public_photos.first }
  let(:middle_public_photo) { public_photos[1] }
  let(:last_public_photo) { public_photos.last }

  describe 'public fields query' do
    let(:query) do
      <<~GQL
        query {
          album(id: "#{album.slug}") {
            id
            title
            description
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
            sortingType
            sortingOrder
            canEdit
            previousPhotoInAlbum(photoId: "#{middle_public_photo.slug}") { id }
            nextPhotoInAlbum(photoId: "#{middle_public_photo.slug}") { id }
          }
        }
      GQL
    end

    before do
      album.maintenance
    end

    it 'returns the correct album' do
      post_query

      parsed_body = response.parsed_body
      response_album = parsed_body['data']['album']

      expect(response_album['id']).to eq(album.slug)
      expect(response_album['title']).to eq(album.title)
      expect(response_album['photos']['collection'].size).to eq(public_photos.size)
      expect(response_album['sortingType']).to eq(album.graphql_sorting_type)
      expect(response_album['sortingOrder']).to eq(album.sorting_order)
      expect(response_album['canEdit']).to be_falsey
      expect(response_album['previousPhotoInAlbum']['id']).to eq(first_public_photo.slug)
      expect(response_album['nextPhotoInAlbum']['id']).to eq(last_public_photo.slug)
    end
  end

  describe 'private fields query' do
    context 'when the user is not logged in' do
      describe 'allPhotos field' do
        let(:query) do
          <<~GQL
            query {
              album(id: "#{album.slug}") {
                id
                allPhotos {
                  id
                }
              }
            }
          GQL
        end

        it 'returns a NOT_FOUND error on allPhotos and nulls the field' do
          post_query
          parsed = response.parsed_body
          err = parsed['errors']&.first

          expect(err).to be_present
          expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
          expect(err['path']).to eq(%w[album allPhotos])

          # Parent object can still resolve
          expect(parsed.dig('data', 'album', 'id')).to eq(album.slug)
          # The unauthorized field is nulled
          expect(parsed.dig('data', 'album', 'allPhotos')).to be_nil
        end
      end
    end

    context 'when the user is logged in' do
      before do
        sign_in(user)
        # these fields are set by the maintenance method
        album.maintenance
      end

      describe 'allPhotos field' do
        let(:query) do
          <<~GQL
            query {
              album(id: "#{album.slug}") {
                id
                allPhotos {
                  id
                  ordering
                }
              }
            }
          GQL
        end

        it 'returns all photos in the album' do
          post_query

          parsed_body = response.parsed_body
          response_album = parsed_body['data']['album']

          expect(response_album['allPhotos'].size).to eq(public_photos.size + private_photos.size)
          expect(response_album['allPhotos'][1]['ordering']).to eq(200_000)
        end
      end
    end
  end

  describe 'album visibility and cover photo by role (single album query)' do
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
    let!(:owner)    { create(:user) }
    let!(:stranger) { create(:user) }
    let!(:admin)    { create(:user, admin: true) }

    # 1) Private album with only private photos; user set cover is a private photo
    let!(:album1) { create(:album, user: owner, privacy: :private, sorting_type: :manual) }
    let!(:a1p1_private) { create(:photo, user: owner, privacy: :private) }
    let!(:a1p2_private) { create(:photo, user: owner, privacy: :private) }

    # 2) Public album with only private photos; user set cover is a private photo
    let!(:album2) { create(:album, user: owner, privacy: :public, sorting_type: :manual) }
    let!(:a2p1_private) { create(:photo, user: owner, privacy: :private) }
    let!(:a2p2_private) { create(:photo, user: owner, privacy: :private) }

    # 3) Public album with only public photos; user set cover is a public photo
    let!(:album3) { create(:album, user: owner, privacy: :public, sorting_type: :manual) }
    let!(:a3p1_public) { create(:photo, user: owner) }
    let!(:a3p2_public) { create(:photo, user: owner) }

    # 4) Public album with both private and public photos; user set cover is a private photo
    let!(:album4) { create(:album, user: owner, privacy: :public, sorting_type: :manual) }
    let!(:a4p1_public)  { create(:photo, user: owner) }
    let!(:a4p2_private) { create(:photo, user: owner, privacy: :private) }
    let!(:a4p3_public)  { create(:photo, user: owner) }

    before do
      # Album 1
      album1.photos << [a1p1_private, a1p2_private]
      album1.update!(user_cover_photo_id: a1p1_private.id)
      album1.maintenance

      # Album 2
      album2.photos << [a2p1_private, a2p2_private]
      album2.update!(user_cover_photo_id: a2p1_private.id)
      album2.maintenance

      # Album 3 (user cover is public => becomes public cover too)
      album3.photos << [a3p1_public, a3p2_public]
      album3.update!(user_cover_photo_id: a3p2_public.id)
      album3.maintenance

      # Album 4 (first public photo should be a4p1_public for visitors)
      album4.photos << [a4p1_public, a4p2_private, a4p3_public]
      album4.update!(user_cover_photo_id: a4p2_private.id)
      album4.maintenance
    end

    def post_album(id)
      post '/graphql', params: { query: query_for(id) }
      response.parsed_body
    end

    def collection_map(parsed_body)
      (parsed_body.dig('data', 'album', 'photos', 'collection') || []).index_by { |p| p['id'] }
    end

    context 'as a visitor (not logged in)' do
      it 'album one returns a NOT_FOUND error and nulls the album' do
        parsed = post_album(album1.slug)
        err = parsed['errors']&.first

        expect(err).to be_present
        expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
        expect(err['path']).to eq(['album'])
        expect(parsed.dig('data', 'album')).to be_nil
      end

      it 'album two returns an album without photos' do
        parsed = post_album(album2.slug)
        expect(parsed['errors']).to be_nil.or be_empty
        expect(parsed.dig('data', 'album', 'id')).to eq(album2.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(0)
        expect(parsed.dig('data', 'album', 'photos', 'collection')).to eq([])
      end

      it "album three returns all photos (they're public) and isCoverPhoto is true for the user-set public cover" do
        parsed = post_album(album3.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album3.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        # user-set cover is a3p2_public and should also be the public cover
        expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
      end

      it 'album four returns only public photos and isCoverPhoto is true for the first public photo' do
        parsed = post_album(album4.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album4.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        # first public photo in insertion order is a4p1_public
        expect(map[a4p1_public.slug]['isCoverPhoto']).to be(true)
        # ensure private cover is not visible nor flagged (private photo not in collection)
        expect(map[a4p2_private.slug]).to be_nil
      end
    end

    context 'as a logged-in non-owner' do
      before { sign_in(stranger) }

      it 'behaves the same as a visitor for album one (NOT_FOUND error and null album)' do
        parsed = post_album(album1.slug)
        err = parsed['errors']&.first

        expect(err).to be_present
        expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
        expect(err['path']).to eq(['album'])
        expect(parsed.dig('data', 'album')).to be_nil
      end

      it 'behaves the same as a visitor for album two (no photos)' do
        parsed = post_album(album2.slug)
        expect(parsed['errors']).to be_nil.or be_empty
        expect(parsed.dig('data', 'album', 'id')).to eq(album2.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(0)
        expect(parsed.dig('data', 'album', 'photos', 'collection')).to eq([])
      end

      it 'behaves the same as a visitor for album three (public cover photo flagged)' do
        parsed = post_album(album3.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album3.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
      end

      it 'behaves the same as a visitor for album four (first public photo flagged)' do
        parsed = post_album(album4.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album4.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a4p1_public.slug]['isCoverPhoto']).to be(true)
        expect(map[a4p2_private.slug]).to be_nil
      end
    end

    context 'as the owner' do
      before { sign_in(owner) }

      it 'album one returns all photos; user-set cover flagged' do
        parsed = post_album(album1.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album1.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a1p1_private.slug]['isCoverPhoto']).to be(true)
      end

      it 'album two returns all photos; user-set cover flagged' do
        parsed = post_album(album2.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album2.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a2p1_private.slug]['isCoverPhoto']).to be(true)
      end

      it 'album three returns all photos; user-set (public) cover flagged' do
        parsed = post_album(album3.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album3.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
      end

      it 'album four returns all photos; user-set (private) cover flagged' do
        parsed = post_album(album4.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album4.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(3)
        expect(map[a4p2_private.slug]['isCoverPhoto']).to be(true)
      end
    end

    context 'as an admin' do
      before { sign_in(admin) }

      it 'album one returns all photos; user-set cover flagged' do
        parsed = post_album(album1.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album1.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a1p1_private.slug]['isCoverPhoto']).to be(true)
      end

      it 'album two returns all photos; user-set cover flagged' do
        parsed = post_album(album2.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album2.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a2p1_private.slug]['isCoverPhoto']).to be(true)
      end

      it 'album three returns all photos; user-set (public) cover flagged' do
        parsed = post_album(album3.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album3.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(2)
        expect(map[a3p2_public.slug]['isCoverPhoto']).to be(true)
      end

      it 'album four returns all photos; user-set (private) cover flagged' do
        parsed = post_album(album4.slug)
        map = collection_map(parsed)
        expect(parsed.dig('data', 'album', 'id')).to eq(album4.slug)
        expect(parsed.dig('data', 'album', 'photos', 'metadata', 'totalCount')).to eq(3)
        expect(map[a4p2_private.slug]['isCoverPhoto']).to be(true)
      end
    end
  end
end

describe 'unknown album slug' do
  let(:query) do
    <<~GQL
      query {
        album(id: "unknown-slug") {
          id
        }
      }
    GQL
  end

  it 'returns NOT_FOUND error and null album' do
    post '/graphql', params: { query: query }
    parsed = response.parsed_body
    err = parsed['errors']&.first

    expect(err).to be_present
    expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    expect(err['path']).to eq(['album'])
    expect(parsed.dig('data', 'album')).to be_nil
  end
end
