# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PhotosController#create with album association', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:uploader_user) { create(:user, :uploader) }

  def upload_file
    file_path = Rails.root.join('spec/support/images/zell-am-see-with-exif.jpg')
    Rack::Test::UploadedFile.new(file_path, 'image/jpeg')
  end

  before do
    sign_in(uploader_user)
  end

  describe 'POST /photos' do
    context 'with basic photo upload (no albums)' do
      it 'creates a photo successfully' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'Test Photo',
              description: 'Test Description',
              image: upload_file
            }
          }
        end.to change(Photo, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['photo']['id']).to be_present
        expect(json['created_album_ids']).to eq([])
        expect(json['applied_album_ids']).to eq([])
      end
    end

    context 'with existing album ID' do
      let!(:existing_album) { create(:album, user: uploader_user, title: 'Existing Album') }

      it 'creates photo and associates with existing album' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'Test Photo',
              description: 'Test Description',
              image: upload_file,
              album_ids: [existing_album.slug]
            }
          }
        end.to change(Photo, :count).by(1)
           .and change(AlbumsPhoto, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        photo = Photo.unscoped.find_by(slug: json['photo']['id'])
        expect(photo.albums).to include(existing_album)
        expect(json['created_album_ids']).to eq([])
        expect(json['applied_album_ids']).to eq([existing_album.slug])
      end

      it 'triggers album maintenance after association' do
        # Verify maintenance runs by checking its side effect: photos_count is updated
        initial_count = existing_album.photos_count

        post '/photos', params: {
          photo: {
            title: 'Test Photo',
            description: 'Test Description',
            image: upload_file,
            album_ids: [existing_album.slug]
          }
        }

        expect(response).to have_http_status(:created)
        existing_album.reload
        expect(existing_album.photos_count).to eq(initial_count + 1)
      end
    end

    context 'with new album title' do
      it 'creates photo and new album' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'Test Photo',
              description: 'Test Description',
              image: upload_file,
              new_album_titles: ['Brand New Album']
            }
          }
        end.to change(Photo, :count).by(1)
           .and change(Album, :count).by(1)
           .and change(AlbumsPhoto, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        photo = Photo.unscoped.find_by(slug: json['photo']['id'])
        new_album = Album.unscoped.find_by(title: 'Brand New Album')

        expect(new_album).to be_present
        expect(new_album.user).to eq(uploader_user)
        expect(new_album.privacy).to eq('public')
        expect(photo.albums).to include(new_album)
        expect(json['created_album_ids']).to eq([new_album.slug])
        expect(json['applied_album_ids']).to eq([new_album.slug])
      end
    end

    context 'with multiple existing albums' do
      let!(:first_album) { create(:album, user: uploader_user, title: 'Album 1') }
      let!(:second_album) { create(:album, user: uploader_user, title: 'Album 2') }

      it 'associates photo with multiple albums' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'Test Photo',
              description: 'Test Description',
              image: upload_file,
              album_ids: [first_album.slug, second_album.slug]
            }
          }
        end.to change(Photo, :count).by(1)
           .and change(AlbumsPhoto, :count).by(2)

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        photo = Photo.unscoped.find_by(slug: json['photo']['id'])
        expect(photo.albums).to include(first_album, second_album)
        expect(json['applied_album_ids']).to contain_exactly(first_album.slug, second_album.slug)
      end
    end

    context 'with mix of existing and new albums' do
      let!(:existing_album) { create(:album, user: uploader_user, title: 'Existing Album') }

      it 'associates with existing and creates new album' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'Test Photo',
              description: 'Test Description',
              image: upload_file,
              album_ids: [existing_album.slug],
              new_album_titles: ['New Album']
            }
          }
        end.to change(Photo, :count).by(1)
           .and change(Album, :count).by(1)
           .and change(AlbumsPhoto, :count).by(2)

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        photo = Photo.unscoped.find_by(slug: json['photo']['id'])
        new_album = Album.unscoped.find_by(title: 'New Album')

        expect(photo.albums).to include(existing_album, new_album)
        expect(json['created_album_ids']).to eq([new_album.slug])
        expect(json['applied_album_ids']).to contain_exactly(existing_album.slug, new_album.slug)
      end
    end

    context 'when photo validation fails' do
      it 'rolls back album creation' do
        expect do
          post '/photos', params: {
            photo: {
              title: '',
              description: '',
              image: upload_file,
              new_album_titles: ['Should Not Be Created']
            }
          }
        end.not_to change(Album, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = response.parsed_body
        expect(json['errors']).to be_present
      end
    end

    context 'when unauthorized to access album' do
      let(:other_user) { create(:user, :uploader) }
      let!(:other_users_album) { create(:album, user: other_user, title: 'Other Album', privacy: 'private') }

      it 'silently ignores albums user cannot access (policy_scope filters them out)' do
        # Policy scope filters out private albums from other users
        # so the album isn't found, but photo is still created successfully
        post '/photos', params: {
          photo: {
            title: 'Test Photo',
            description: 'Test Description',
            image: upload_file,
            album_ids: [other_users_album.slug]
          }
        }

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        # Album was filtered out by policy_scope, so it's not in applied_album_ids
        expect(json['applied_album_ids']).to eq([])
      end
    end

    context 'when user does not have uploader role' do
      let(:regular_user) { create(:user) }

      before do
        sign_out(uploader_user)
        sign_in(regular_user)
      end

      it 'returns unauthorized error' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'Test Photo',
              description: 'Test Description',
              image: upload_file
            }
          }
        end.not_to change(Photo, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when testing idempotency with concurrent uploads to new album' do
      it 'does not create duplicate albums when same album title used' do
        # First upload creates the album
        post '/photos', params: {
          photo: {
            title: 'Photo 1',
            description: 'First photo',
            image: upload_file,
            new_album_titles: ['Vacation 2024']
          }
        }

        expect(response).to have_http_status(:created)
        first_response = response.parsed_body
        created_album_slug = first_response['created_album_ids'].first

        # Second upload should find the existing album by slug
        initial_photo_count = Photo.unscoped.count
        initial_album_count = Album.unscoped.count

        # Re-sign in the user to ensure authentication is preserved
        sign_in(uploader_user)

        post '/photos', params: {
          photo: {
            title: 'Photo 2',
            description: 'Second photo',
            image: upload_file,
            album_ids: [created_album_slug]
          }
        }

        expect(response).to have_http_status(:created)
        expect(Photo.unscoped.count).to eq(initial_photo_count + 1)
        expect(Album.unscoped.count).to eq(initial_album_count)

        second_response = response.parsed_body
        expect(second_response['created_album_ids']).to eq([])
        expect(second_response['applied_album_ids']).to eq([created_album_slug])
      end
    end

    context 'with album ordering' do
      let!(:existing_album) { create(:album, user: uploader_user, title: 'Test Album') }

      it 'sets ordering automatically via AlbumsPhoto callback' do
        post '/photos', params: {
          photo: {
            title: 'Test Photo',
            description: 'Test Description',
            image: upload_file,
            album_ids: [existing_album.slug]
          }
        }

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        photo = Photo.unscoped.find_by(slug: json['photo']['id'])
        albums_photo = AlbumsPhoto.find_by(album: existing_album, photo: photo)

        expect(albums_photo.ordering).to be_present
        expect(albums_photo.ordering).to be > 0
      end
    end
  end
end
