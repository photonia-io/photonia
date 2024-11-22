# frozen_string_literal: true

require 'rails_helper'

describe 'updatePhotoDescription Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:title) { 'Test title' }
  let(:description) { 'Test description' }
  let(:photo) { create(:photo, title: title, description: description) }

  let(:new_description) { 'New test description' }

  let(:query) do
    <<~GQL
      mutation {
        updatePhotoDescription(
          id: "#{photo.slug}"
          description: "#{new_description}"
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

    it 'updates the photo description' do
      post_mutation
      json = JSON.parse(response.body)
      data = json['data']['updatePhotoDescription']

      expect(data).to include(
        'id' => photo.slug,
        'title' => title,
        'description' => new_description
      )
    end

    context 'when updating to an empty description' do
      let(:new_description) { '' }

      it 'updates the photo description' do
        post_mutation
        json = JSON.parse(response.body)
        data = json['data']['updatePhotoDescription']

        expect(data).to include(
          'id' => photo.slug,
          'title' => title,
          'description' => new_description
        )
      end

      context 'when the title is also empty' do
        let(:title) { '' }

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
