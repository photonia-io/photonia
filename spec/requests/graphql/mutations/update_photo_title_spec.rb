# frozen_string_literal: true

require 'rails_helper'

describe 'updatePhotoTitle Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:title) { 'Test title' }
  let(:description) { 'Test description' }
  let(:photo) { create(:photo, title: title, description: description) }

  let(:new_title) { 'New test title' }

  let(:query) do
    <<~GQL
      mutation {
        updatePhotoTitle(
          id: "#{photo.id}"
          title: "#{new_title}"
        ) {
          id
          title
          description
        }
      }
    GQL
  end

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  context 'when the user is not logged in' do
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(photo.user)
    end

    it 'updates the photo title' do
      post_mutation
      json = JSON.parse(response.body)
      data = json['data']['updatePhotoTitle']

      expect(data).to include(
        'id' => photo.slug,
        'title' => new_title,
        'description' => description
      )
    end

    context 'when updating to an empty title' do
      let(:new_title) { '' }

      it 'updates the photo title' do
        post_mutation
        json = JSON.parse(response.body)
        data = json['data']['updatePhotoTitle']

        expect(data).to include(
          'id' => photo.slug,
          'title' => new_title,
          'description' => description
        )
      end

      context 'when the description is also empty' do
        let(:description) { '' }

        it 'raises an error' do
          post_mutation
          json = JSON.parse(response.body)
          errors = json['errors'].first

          expect(errors['message']).to eq('Either title or description is required')
        end
      end
    end
  end
end
