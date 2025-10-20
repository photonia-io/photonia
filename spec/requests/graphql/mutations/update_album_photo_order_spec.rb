# frozen_string_literal: true

require 'rails_helper'

describe 'updateAlbumPhotoOrder Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:album) { create(:album) }
  let(:user) { album.user }
  let(:first_photo) { create(:photo, user: user, title: 'X', taken_at: 10.seconds.ago, created_at: 10.seconds.ago) }
  let(:second_photo) { create(:photo, user: user, title: 'A', taken_at: Time.current, created_at: Time.current) }

  before do
    album.photos << first_photo
    album.photos << second_photo
  end

  context 'when the album is not found' do
    before do
      album.destroy
    end

    let(:query) do
      <<~GQL
        mutation {
          updateAlbumPhotoOrder(
            albumId: "#{album.slug}"
            sortingType: "manual"
            sortingOrder: "asc"
          ) {
            album { id }
            errors
          }
        }
      GQL
    end

    it 'returns an error payload' do
      post_mutation
      payload = data_dig(response, 'updateAlbumPhotoOrder')
      expect(payload['album']).to be_nil
      expect(payload['errors']).to be_present
      expect(payload['errors']).to include('Album not found')
    end
  end

  context 'when the user is not logged in' do
    let(:query) do
      <<~GQL
        mutation {
          updateAlbumPhotoOrder(
            albumId: "#{album.slug}"
            sortingType: "manual"
            sortingOrder: "asc"
          ) {
            album { id }
            errors
          }
        }
      GQL
    end

    it 'returns an authorization error' do
      post_mutation
      payload = data_dig(response, 'updateAlbumPhotoOrder')
      expect(payload['album']).to be_nil
      expect(payload['errors']).to be_present
      expect(payload['errors']).to include('Not authorized to update this album')
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(album.user)
    end

    context 'when updating sorting type to takenAt and order to desc' do
      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "takenAt"
              sortingOrder: "desc"
            ) {
              album {
                id
                sortingType
                sortingOrder
                photos {
                  collection { id }
                }
              }
              errors
            }
          }
        GQL
      end

      it 'updates the album sorting fields and returns photos in the correct order' do
        post_mutation
        album_data = data_dig(response, 'updateAlbumPhotoOrder', 'album')
        expect(album_data).to include(
          'id' => album.slug,
          'sortingType' => 'takenAt',
          'sortingOrder' => 'desc'
        )
        expect(album_data['photos']['collection'][0]).to eq(
          'id' => second_photo.slug
        )
        expect(album_data['photos']['collection'][1]).to eq(
          'id' => first_photo.slug
        )
      end
    end

    context 'when updating sorting type to postedAt and order to desc' do
      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "postedAt"
              sortingOrder: "desc"
            ) {
              album {
                id
                sortingType
                sortingOrder
                photos {
                  collection { id }
                }
              }
              errors
            }
          }
        GQL
      end

      it 'updates the album sorting fields and returns photos in the correct order' do
        post_mutation
        album_data = data_dig(response, 'updateAlbumPhotoOrder', 'album')
        expect(album_data).to include(
          'id' => album.slug,
          'sortingType' => 'postedAt',
          'sortingOrder' => 'desc'
        )
        expect(album_data['photos']['collection'][0]).to eq(
          'id' => second_photo.slug
        )
        expect(album_data['photos']['collection'][1]).to eq(
          'id' => first_photo.slug
        )
      end
    end

    context 'when updating sorting type to title and order to asc' do
      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "title"
              sortingOrder: "asc"
            ) {
              album {
                id
                sortingType
                sortingOrder
                photos {
                  collection { id }
                }
              }
              errors
            }
          }
        GQL
      end

      it 'updates the album sorting fields and returns photos in the correct order' do
        post_mutation
        album_data = data_dig(response, 'updateAlbumPhotoOrder', 'album')
        expect(album_data).to include(
          'id' => album.slug,
          'sortingType' => 'title',
          'sortingOrder' => 'asc'
        )
        expect(album_data['photos']['collection'][0]).to eq(
          'id' => second_photo.slug
        )
        expect(album_data['photos']['collection'][1]).to eq(
          'id' => first_photo.slug
        )
      end
    end

    context 'when valid orders are provided' do
      let(:first_photo_order) { 300_000 }
      let(:second_photo_order) { 100_000 }

      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "manual"
              sortingOrder: "asc"
              orders: [
                { photoId: "#{first_photo.slug}", ordering: #{first_photo_order} },
                { photoId: "#{second_photo.slug}", ordering: #{second_photo_order} }
              ]
            ) {
              album {
                id
                sortingType
                sortingOrder
                photos {
                  collection { id }
                }
              }
              errors
            }
          }
        GQL
      end

      it 'updates the album sorting fields and returns photos in the correct order' do
        post_mutation
        album_data = data_dig(response, 'updateAlbumPhotoOrder', 'album')
        expect(album_data).to include(
          'id' => album.slug,
          'sortingType' => 'manual',
          'sortingOrder' => 'asc'
        )
        expect(album_data['photos']['collection'][0]).to eq(
          'id' => second_photo.slug
        )
        expect(album_data['photos']['collection'][1]).to eq(
          'id' => first_photo.slug
        )
      end
    end

    context 'when an invalid sorting type is provided' do
      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "invalid"
              sortingOrder: "asc"
            ) {
              album { id }
              errors
            }
          }
        GQL
      end

      it 'returns an error in the payload' do
        post_mutation
        payload = data_dig(response, 'updateAlbumPhotoOrder')
        expect(payload['album']).to be_nil
        expect(payload['errors']).to include('Invalid sorting type')
      end
    end

    context 'when an invalid sorting order is provided' do
      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "title"
              sortingOrder: "invalid"
            ) {
              album { id }
              errors
            }
          }
        GQL
      end

      it 'returns an error in the payload' do
        post_mutation
        payload = data_dig(response, 'updateAlbumPhotoOrder')
        expect(payload['album']).to be_nil
        expect(payload['errors']).to include('Invalid sorting order')
      end
    end

    context 'when a provided photo does not exist' do
      let(:missing_slug) { 'nonexistent-photo' }
      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "manual"
              sortingOrder: "asc"
              orders: [
                { photoId: "#{missing_slug}", ordering: 100000 }
              ]
            ) {
              album { id }
              errors
            }
          }
        GQL
      end

      it 'returns an error in the payload' do
        post_mutation
        payload = data_dig(response, 'updateAlbumPhotoOrder')
        expect(payload['album']).to be_nil
        expect(payload['errors']).to include("Photo #{missing_slug} not found")
      end
    end

    context 'when a provided photo is not in the album' do
      let(:other_photo) { create(:photo, user: album.user) }
      let(:query) do
        <<~GQL
          mutation {
            updateAlbumPhotoOrder(
              albumId: "#{album.slug}"
              sortingType: "manual"
              sortingOrder: "asc"
              orders: [
                { photoId: "#{other_photo.slug}", ordering: 100000 }
              ]
            ) {
              album { id }
              errors
            }
          }
        GQL
      end

      it 'returns an error in the payload' do
        post_mutation
        payload = data_dig(response, 'updateAlbumPhotoOrder')
        expect(payload['album']).to be_nil
        expect(payload['errors']).to include("Photo #{other_photo.slug} not found in album")
      end
    end
  end
end
