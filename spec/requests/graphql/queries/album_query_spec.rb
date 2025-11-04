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
