# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Photo Upload Integration Tests', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:uploader_user) { create(:user, :uploader) }

  def upload_file
    file_path = Rails.root.join('spec/support/images/zell-am-see-with-exif.jpg')
    Rack::Test::UploadedFile.new(file_path, 'image/jpeg')
  end

  before do
    sign_in(uploader_user)
  end

  describe 'Multi-file upload scenarios' do
    context 'when uploading single file to existing album' do
      let!(:existing_album) { create(:album, user: uploader_user, title: 'Summer Vacation') }

      it 'successfully uploads and associates photo' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'Beach Photo',
              description: 'Beautiful beach',
              image: upload_file,
              album_ids: [existing_album.slug]
            }
          }
        end.to change(Photo, :count).by(1)
           .and change { existing_album.reload.photos_count }.by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        photo = Photo.unscoped.find_by(slug: json['photo']['id'])
        expect(photo.albums).to include(existing_album)
      end
    end

    context 'when uploading single file to new album' do
      it 'creates album and associates photo' do
        expect do
          post '/photos', params: {
            photo: {
              title: 'First Photo',
              description: 'Starting a new collection',
              image: upload_file,
              new_album_titles: ['New Collection']
            }
          }
        end.to change(Photo, :count).by(1)
           .and change(Album, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        new_album = Album.unscoped.find_by(title: 'New Collection')
        expect(new_album).to be_present
        expect(new_album.photos_count).to eq(1)
        expect(json['created_album_ids']).to eq([new_album.slug])
      end
    end

    context 'when batch uploading to new album verifies single album created' do
      it 'creates only one album for multiple photos' do
        # Simulate batch upload: first file creates album
        post '/photos', params: {
          photo: {
            title: 'Photo 1',
            description: 'First of batch',
            image: upload_file,
            new_album_titles: ['Batch Album 2024']
          }
        }

        expect(response).to have_http_status(:created)
        first_response = response.parsed_body
        created_album_slug = first_response['created_album_ids'].first
        expect(created_album_slug).to be_present

        # Second file uses the created album slug (idempotency)
        sign_in(uploader_user)
        post '/photos', params: {
          photo: {
            title: 'Photo 2',
            description: 'Second of batch',
            image: upload_file,
            album_ids: [created_album_slug]
          }
        }

        expect(response).to have_http_status(:created)

        second_response = response.parsed_body
        expect(second_response['created_album_ids']).to eq([])
        expect(second_response['applied_album_ids']).to eq([created_album_slug])

        # Third file also uses existing album
        sign_in(uploader_user)
        post '/photos', params: {
          photo: {
            title: 'Photo 3',
            description: 'Third of batch',
            image: upload_file,
            album_ids: [created_album_slug]
          }
        }

        expect(response).to have_http_status(:created)

        # Verify album has all 3 photos
        album = Album.unscoped.find_by(slug: created_album_slug)
        expect(album.photos_count).to eq(3)
      end
    end

    context 'when batch uploading and first file fails no album is created' do
      it 'does not create album when photo validation fails' do
        expect do
          post '/photos', params: {
            photo: {
              title: '',
              description: '',
              image: upload_file,
              new_album_titles: ['Should Not Exist']
            }
          }
        end.not_to change(Album, :count)

        expect(response).to have_http_status(:unprocessable_content)

        # Verify album was not created
        expect(Album.unscoped.find_by(title: 'Should Not Exist')).to be_nil
      end
    end

    context 'when batch uploading with partial success' do
      it 'creates album with only successful photos' do
        # First upload succeeds
        post '/photos', params: {
          photo: {
            title: 'Success 1',
            description: 'This will work',
            image: upload_file,
            new_album_titles: ['Partial Success Album']
          }
        }

        expect(response).to have_http_status(:created)
        first_response = response.parsed_body
        album_slug = first_response['created_album_ids'].first

        # Second upload succeeds
        sign_in(uploader_user)
        post '/photos', params: {
          photo: {
            title: 'Success 2',
            description: 'This will also work',
            image: upload_file,
            album_ids: [album_slug]
          }
        }

        expect(response).to have_http_status(:created)

        # Third upload fails (validation error)
        sign_in(uploader_user)
        post '/photos', params: {
          photo: {
            title: '',
            description: '',
            image: upload_file,
            album_ids: [album_slug]
          }
        }

        expect(response).to have_http_status(:unprocessable_content)

        # Album should exist with 2 photos
        album = Album.unscoped.find_by(slug: album_slug)
        expect(album).to be_present
        expect(album.photos_count).to eq(2)
      end
    end

    context 'when concurrent uploading to existing album' do
      let!(:existing_album) { create(:album, user: uploader_user, title: 'Concurrent Album') }

      it 'handles multiple photos added to same album' do
        # First upload
        post '/photos', params: {
          photo: {
            title: 'Concurrent 1',
            description: 'First concurrent upload',
            image: upload_file,
            album_ids: [existing_album.slug]
          }
        }

        # Second upload
        sign_in(uploader_user)
        post '/photos', params: {
          photo: {
            title: 'Concurrent 2',
            description: 'Second concurrent upload',
            image: upload_file,
            album_ids: [existing_album.slug]
          }
        }

        existing_album.reload
        expect(existing_album.photos_count).to eq(2)

        expect(existing_album.photos.count).to eq(2)
      end
    end

    context 'when uploading with privacy settings' do
      it 'creates new album with default public privacy' do
        post '/photos', params: {
          photo: {
            title: 'Privacy Test Photo',
            description: 'Testing privacy',
            image: upload_file,
            new_album_titles: ['Privacy Test Album']
          }
        }

        expect(response).to have_http_status(:created)
        json = response.parsed_body

        album = Album.unscoped.find_by(slug: json['created_album_ids'].first)
        expect(album.privacy).to eq('public')
      end
    end

    context 'when album maintenance triggers' do
      let!(:album) { create(:album, user: uploader_user, title: 'Maintenance Album', sorting_type: 'posted_at') }

      it 'triggers album maintenance after photo association' do
        initial_cover = album.public_cover_photo_id

        post '/photos', params: {
          photo: {
            title: 'New Cover Photo',
            description: 'Should update album cover',
            image: upload_file,
            album_ids: [album.slug]
          }
        }

        expect(response).to have_http_status(:created)

        album.reload
        expect(album.public_cover_photo_id).not_to eq(initial_cover)
        expect(album.photos_count).to eq(1)
      end
    end

    context 'with album ordering' do
      let!(:album) { create(:album, user: uploader_user, title: 'Ordering Album') }

      it 'assigns ordering to photos in the album' do
        post '/photos', params: {
          photo: {
            title: 'First Photo',
            description: 'Should have ordering',
            image: upload_file,
            album_ids: [album.slug]
          }
        }

        expect(response).to have_http_status(:created)
        first_response = response.parsed_body
        first_photo = Photo.unscoped.find_by(slug: first_response['photo']['id'])

        sign_in(uploader_user)
        post '/photos', params: {
          photo: {
            title: 'Second Photo',
            description: 'Should have higher ordering',
            image: upload_file,
            album_ids: [album.slug]
          }
        }

        expect(response).to have_http_status(:created)
        second_response = response.parsed_body
        second_photo = Photo.unscoped.find_by(slug: second_response['photo']['id'])

        first_ordering = AlbumsPhoto.find_by(album: album, photo: first_photo).ordering
        second_ordering = AlbumsPhoto.find_by(album: album, photo: second_photo).ordering

        expect(first_ordering).to be < second_ordering
      end
    end

    context 'with error handling' do
      it 'returns proper error response on validation failure' do
        post '/photos', params: {
          photo: {
            title: '',
            description: '',
            image: upload_file,
            new_album_titles: ['Error Album']
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        json = response.parsed_body
        expect(json['errors']).to be_an(Array)
        expect(json['errors']).not_to be_empty
      end

      it 'handles missing album gracefully (silently ignores)' do
        post '/photos', params: {
          photo: {
            title: 'Test Photo',
            description: 'Test',
            image: upload_file,
            album_ids: ['non-existent-slug']
          }
        }

        # Non-existent album is simply not found, photo still created
        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['applied_album_ids']).to eq([])
      end
    end
  end
end
