# frozen_string_literal: true

require 'rails_helper'

describe 'currentUser Query' do
  include Devise::Test::IntegrationHelpers

  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:email) { Faker::Internet.email }
  let(:first_name) { Faker::Name.first_name }
  let(:last_name) { Faker::Name.last_name }
  let(:display_name) { Faker::Name.name }
  let(:timezone) { ActiveSupport::TimeZone.all.sample.name }

  let(:query) do
    <<~GQL
      query {
        currentUser {
          id
          email
          firstName
          lastName
          displayName
          timezone {
            name
          }
          admin
          uploader
        }
      }
    GQL
  end

  context 'when the user is not logged in' do
    it 'returns an error message in the GraphQL response' do
      post_query

      json = JSON.parse(response.body)

      expect(json['errors'][0]).to include(
        'message' => 'User not signed in'
      )
    end
  end

  context 'when the user is logged in' do
    def sign_in_and_post_query(user)
      sign_in(user)
      post_query
    end

    context 'and is a registered user' do
      let!(:user) do
        create(:user, email: email, first_name: first_name, last_name: last_name, display_name: display_name,
                      timezone: timezone)
      end

      before do
        sign_in_and_post_query(user)
      end

      it_behaves_like 'current user', admin: false, uploader: false
    end

    context 'and is an uploader' do
      let!(:user) do
        create(:user, :uploader, email: email, first_name: first_name, last_name: last_name, display_name: display_name,
                                 timezone: timezone)
      end
      let(:albums) { create_list(:album, 2, user: user) }
      let(:photos) { create_list(:photo, 3, user: user) }
      let(:photo_slug_list) { photos.map { |photo| "\"#{photo.slug}\"" }.join(', ') }

      let(:query) do
        <<~GQL
          query {
            currentUser {
              id
              email
              firstName
              lastName
              displayName
              timezone {
                name
              }
              admin
              uploader
              albums {
                id
                title
                photosCount
              }
              albumsWithPhotos(photoIds: [#{photo_slug_list}]) {
                id
                title
                containedPhotosCount
              }
            }
          }
        GQL
      end

      before do
        albums.first.photos << photos
        albums.first.maintenance
        sign_in_and_post_query(user)
      end

      it_behaves_like 'current user', admin: false, uploader: true

      it 'returns the user with their albums' do
        expect(response.parsed_body['data']['currentUser']['albums']).to contain_exactly(
          {
            'id' => albums.first.slug,
            'title' => albums.first.title,
            'photosCount' => 3
          },
          {
            'id' => albums.second.slug,
            'title' => albums.second.title,
            'photosCount' => 0
          }
        )
      end

      it 'returns the user with their albumsWithPhotos' do
        expect(response.parsed_body['data']['currentUser']['albumsWithPhotos']).to contain_exactly(
          {
            'id' => albums.first.slug,
            'title' => albums.first.title,
            'containedPhotosCount' => 3
          }
        )
      end
    end

    context 'and is an admin' do
      let!(:user) do
        create(:user, admin: true, email: email, first_name: first_name, last_name: last_name, display_name: display_name,
                      timezone: timezone)
      end

      before do
        sign_in_and_post_query(user)
      end

      it_behaves_like 'current user', admin: true, uploader: true
    end
  end
end
