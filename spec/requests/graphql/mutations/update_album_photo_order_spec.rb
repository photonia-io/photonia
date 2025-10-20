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

  def build_mutation(album_id:, sorting_type:, sorting_order:, orders: nil, selection: 'album { id sortingType sortingOrder photos { collection { id } } } errors')
    orders_fragment =
      if orders.present?
        "orders: [\n#{orders.map { |h| "  { photoId: \"#{h[:photo_id]}\", ordering: #{h[:ordering]} }" }.join(",\n")}\n]"
      else
        ''
      end

    <<~GQL
      mutation {
        updateAlbumPhotoOrder(
          albumId: "#{album_id}"
          sortingType: "#{sorting_type}"
          sortingOrder: "#{sorting_order}"
          #{orders_fragment}
        ) {
          #{selection}
        }
      }
    GQL
  end

  def collection_ids(resp)
    data_dig(resp, 'updateAlbumPhotoOrder', 'album', 'photos', 'collection').pluck('id')
  end

  def expect_album_with_order(resp, id:, type:, order:, ids:)
    album_data = data_dig(resp, 'updateAlbumPhotoOrder', 'album')
    expect(album_data).to include(
      'id' => id,
      'sortingType' => type,
      'sortingOrder' => order
    )
    expect(collection_ids(resp)).to eq(ids)
  end

  def ap_order(album, photo)
    AlbumsPhoto.find_by(album_id: album.id, photo_id: photo.id).reload.ordering
  end

  context 'when the album is not found' do
    before { album.destroy }

    let(:query) do
      build_mutation(album_id: album.slug, sorting_type: 'manual', sorting_order: 'asc', selection: 'album { id } errors')
    end

    it 'returns an error payload' do
      post_mutation
      payload = data_dig(response, 'updateAlbumPhotoOrder')
      expect(payload['album']).to be_nil
      expect(payload['errors']).to include('Album not found')
    end
  end

  context 'when the user is not logged in' do
    let(:query) do
      build_mutation(album_id: album.slug, sorting_type: 'manual', sorting_order: 'asc', selection: 'album { id } errors')
    end

    it 'returns an authorization error' do
      post_mutation
      payload = data_dig(response, 'updateAlbumPhotoOrder')
      expect(payload['album']).to be_nil
      expect(payload['errors']).to include('Not authorized to update this album')
    end
  end

  context 'when the user is logged in' do
    before { sign_in(album.user) }

    shared_examples 'updates sorting and returns correct order' do |sorting_type:, sorting_order:|
      let(:query) do
        build_mutation(album_id: album.slug, sorting_type: sorting_type, sorting_order: sorting_order)
      end

      it 'updates the album sorting fields and returns photos in the correct order' do
        post_mutation
        expect_album_with_order(
          response,
          id: album.slug,
          type: sorting_type,
          order: sorting_order,
          ids: [second_photo.slug, first_photo.slug]
        )
      end
    end

    context 'when updating sorting type to takenAt and order to desc' do
      it_behaves_like 'updates sorting and returns correct order', sorting_type: 'takenAt', sorting_order: 'desc'
    end

    context 'when updating sorting type to postedAt and order to desc' do
      it_behaves_like 'updates sorting and returns correct order', sorting_type: 'postedAt', sorting_order: 'desc'
    end

    context 'when updating sorting type to title and order to asc' do
      it_behaves_like 'updates sorting and returns correct order', sorting_type: 'title', sorting_order: 'asc'
    end

    context 'when valid manual orders are provided' do
      let(:first_photo_order) { 300_000 }
      let(:second_photo_order) { 100_000 }

      let(:query) do
        build_mutation(
          album_id: album.slug,
          sorting_type: 'manual',
          sorting_order: 'asc',
          orders: [
            { photo_id: first_photo.slug, ordering: first_photo_order },
            { photo_id: second_photo.slug, ordering: second_photo_order }
          ]
        )
      end

      it 'updates the album sorting fields and returns photos in the correct order' do
        post_mutation
        expect_album_with_order(
          response,
          id: album.slug,
          type: 'manual',
          order: 'asc',
          ids: [second_photo.slug, first_photo.slug]
        )
      end
    end

    context 'when an invalid sorting type is provided' do
      let(:query) do
        build_mutation(album_id: album.slug, sorting_type: 'invalid', sorting_order: 'asc', selection: 'album { id } errors')
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
        build_mutation(album_id: album.slug, sorting_type: 'title', sorting_order: 'invalid', selection: 'album { id } errors')
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
        build_mutation(
          album_id: album.slug,
          sorting_type: 'manual',
          sorting_order: 'asc',
          orders: [
            { photo_id: missing_slug, ordering: 100_000 },
            { photo_id: first_photo.slug, ordering: 300_000 }
          ],
          selection: 'album { id } errors'
        )
      end

      it 'returns an error and does not persist any ordering changes' do
        before_order = ap_order(album, first_photo)
        post_mutation
        expect(data_dig(response, 'updateAlbumPhotoOrder', 'album')).to be_nil
        expect(data_dig(response, 'updateAlbumPhotoOrder', 'errors')).to include("Photo #{missing_slug} not found")
        expect(ap_order(album, first_photo)).to eq(before_order)
      end
    end

    context 'when a provided photo is not in the album' do
      let(:other_photo) { create(:photo, user: album.user) }
      let(:query) do
        build_mutation(
          album_id: album.slug,
          sorting_type: 'manual',
          sorting_order: 'asc',
          orders: [
            { photo_id: other_photo.slug, ordering: 100_000 },
            { photo_id: first_photo.slug, ordering: 300_000 }
          ],
          selection: 'album { id } errors'
        )
      end

      it 'returns an error and does not persist any ordering changes' do
        before_order = ap_order(album, first_photo)
        post_mutation
        expect(data_dig(response, 'updateAlbumPhotoOrder', 'album')).to be_nil
        expect(data_dig(response, 'updateAlbumPhotoOrder', 'errors')).to include("Photo #{other_photo.slug} not found in album")
        expect(ap_order(album, first_photo)).to eq(before_order)
      end
    end
  end
end
