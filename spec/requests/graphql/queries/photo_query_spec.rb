# frozen_string_literal: true

require 'rails_helper'

describe 'photo Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:photo) { create(:photo, image_data: TestData.image_data) }
  let!(:comments) { create_list(:comment, 3, :with_flickr_user, commentable: photo) }

  before do
    photo.populate_exif_fields.save
  end

  context 'when getting a photo by ID' do
    let(:query) do
      <<~GQL
        query {
          photo(id: #{photo.slug}) {
            id
            title
            description
            descriptionHtml
            largeImageUrl: imageUrl(type: "large")
            extralargeImageUrl: imageUrl(type: "extralarge")
            takenAt
            takenAtInfo {
              year
              month
              day
              hour
              minute
              precision
              source
              approximate
              exifAvailable
            }
            scanned
            exifExists
            exifCameraFriendlyName
            exifFNumber
            exifExposureTime
            exifFocalLength
            exifIso
            postedAt
            impressionsCount
            privacy
            comments {
              id
              body
              bodyHtml
              bodyEdited
              bodyLastEditedAt
              flickrUser {
                nsid
                username
                realname
                profileurl
                iconfarm
                iconserver
              }
              createdAt
            }
            canEdit
          }
        }
      GQL
    end

    it 'returns the correct photo and records an impression' do
      expect { post_query }.to change { photo.reload.impressions_count }.by(1)

      parsed_body = response.parsed_body
      response_photo = parsed_body['data']['photo']

      expect(response_photo).to include(
        'id' => photo.slug.to_s,
        'title' => photo.title,
        'description' => photo.description,
        'descriptionHtml' => photo.description_html
      )

      expect(response_photo['largeImageUrl']).to eq photo.image_url(:large)
      expect(response_photo['extralargeImageUrl']).to eq photo.image_url(:extralarge)

      expect(response_photo['takenAt']).to eq photo.taken_at.iso8601
      expect(response_photo['takenAtInfo']).to eq(photo.taken_at_info.deep_transform_keys { |key| key.to_s.camelize(:lower) })
      expect(response_photo['scanned']).to eq photo.scanned

      expect(response_photo['exifExists']).to eq photo.exif_exists?
      expect(response_photo['exifCameraFriendlyName']).to eq photo.exif_camera_friendly_name
      expect(response_photo['exifFNumber']).to eq photo.exif_f_number
      expect(response_photo['exifExposureTime']).to eq photo.exif_exposure_time
      expect(response_photo['exifFocalLength']).to eq photo.exif_focal_length
      expect(response_photo['exifIso']).to eq photo.exif_iso

      expect(response_photo['postedAt']).to eq photo.posted_at.iso8601
      expect(response_photo['impressionsCount']).to eq photo.impressions_count
      expect(response_photo['privacy']).to eq 'public'

      expect(response_photo['comments'].count).to eq 3

      first_comment = comments.first

      response_photo['comments'].first.tap do |comment|
        expect(comment['id']).to eq first_comment.serial_number.to_s
        expect(comment['body']).to eq first_comment.body
        expect(comment['bodyHtml']).to eq first_comment.body_html
        expect(comment['bodyEdited']).to eq first_comment.body_edited?
        expect(comment['bodyLastEditedAt']).to eq first_comment.body_last_edited_at&.iso8601
        expect(comment['createdAt']).to eq first_comment.created_at.iso8601

        comment['flickrUser'].tap do |flickr_user|
          expect(flickr_user['nsid']).to eq first_comment.flickr_user.nsid
          expect(flickr_user['username']).to eq first_comment.flickr_user.username
          expect(flickr_user['realname']).to eq first_comment.flickr_user.realname
          expect(flickr_user['profileurl']).to eq first_comment.flickr_user.profileurl
          expect(flickr_user['iconfarm']).to eq first_comment.flickr_user.iconfarm
          expect(flickr_user['iconserver']).to eq first_comment.flickr_user.iconserver
        end
      end

      expect(response_photo['canEdit']).to be false
    end
  end

  context 'when getting a private photo as its owner' do
    let(:photo) { create(:photo, privacy: :private, image_data: TestData.image_data) }
    let(:query) do
      <<~GQL
        query {
          photo(id: #{photo.slug}) {
            id
            privacy
          }
        }
      GQL
    end

    before do
      sign_in(photo.user)
    end

    it 'returns the private privacy value' do
      post_query
      response_photo = response.parsed_body['data']['photo']

      expect(response_photo['privacy']).to eq 'private'
    end
  end

  context 'when getting the latest photo' do
    let(:query) do
      <<~GQL
        query {
          photo(fetchType: "latest") {
            id
            title
            extralargeImageUrl: imageUrl(type: "extralarge")
          }
        }
      GQL
    end

    it 'returns the latest photo' do
      expect { post_query }.to change { photo.reload.impressions_count }.by(1)

      parsed_body = response.parsed_body
      response_photo = parsed_body['data']['photo']

      expect(response_photo).to include(
        'id' => photo.slug.to_s,
        'title' => photo.title,
        'extralargeImageUrl' => photo.image_url(:extralarge)
      )
    end

    context 'when the actual latest photo is hidden by a collapsed album' do
      let(:album) { create(:album, sorting_type: 'manual', collapsed_in_feed: true) }
      let(:cover) { create(:photo, posted_at: photo.posted_at - 1.hour) }
      let(:hidden_latest) { create(:photo, posted_at: photo.posted_at + 1.hour) }

      before do
        album.photos << cover
        album.photos << hidden_latest
        album.maintenance
      end

      it 'skips it and returns the latest visible photo' do
        post_query
        response_photo = response.parsed_body['data']['photo']

        expect(response_photo['id']).to eq(photo.slug.to_s)
      end
    end

    context 'when the latest photo is a collapsed album\'s cover' do
      let(:album) { create(:album, sorting_type: 'manual', collapsed_in_feed: true) }
      let(:cover) { create(:photo, posted_at: photo.posted_at + 1.hour) }
      let(:other) { create(:photo, posted_at: photo.posted_at + 30.minutes) }

      let(:query) do
        <<~GQL
          query {
            photo(fetchType: "latest") {
              id
              feedAlbum { id title photosCount }
            }
          }
        GQL
      end

      before do
        album.photos << cover
        album.photos << other
        album.maintenance
      end

      it 'carries feedAlbum, standing in for the album' do
        post_query
        response_photo = response.parsed_body['data']['photo']

        expect(response_photo['id']).to eq(cover.slug.to_s)
        expect(response_photo['feedAlbum']).to include(
          'id' => album.slug.to_s,
          'title' => album.title,
          'photosCount' => 2
        )
      end

      it 'has no feedAlbum when that same photo is looked up by id' do
        post '/graphql', params: {
          query: <<~GQL
            query {
              photo(id: "#{cover.slug}") {
                id
                feedAlbum { id }
              }
            }
          GQL
        }
        response_photo = response.parsed_body['data']['photo']

        expect(response_photo['feedAlbum']).to be_nil
      end
    end

    it 'has no feedAlbum for an ordinary latest photo' do
      post '/graphql', params: {
        query: <<~GQL
          query {
            photo(fetchType: "latest") {
              id
              feedAlbum { id }
            }
          }
        GQL
      }
      response_photo = response.parsed_body['data']['photo']

      expect(response_photo['id']).to eq(photo.slug.to_s)
      expect(response_photo['feedAlbum']).to be_nil
    end
  end
end
