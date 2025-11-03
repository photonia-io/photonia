# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'addTagToPhoto Mutation', type: :request do
  include Devise::Test::IntegrationHelpers

  subject(:post_mutation) do
    post '/graphql',
         params: {
           query: query,
           variables: { id: photo_slug, tagName: tag_name }
         }
  end

  let(:photo) { create(:photo) }
  let(:photo_slug) { photo.slug }
  let(:tag_name) { ' TestTag ' }
  let(:normalized_tag_name) { TagNormalizer.normalize(tag_name) }

  let(:query) do
    <<~GRAPHQL
      mutation AddTagToPhoto($id: String!, $tagName: String!) {
        addTagToPhoto(id: $id, tagName: $tagName) {
          photo {
            id
            userTags {
              id
              name
            }
          }
          tag {
            id
            name
          }
        }
      }
    GRAPHQL
  end

  context 'when the user is not logged in' do
    it 'returns NOT_FOUND error and nulls addTagToPhoto' do
      post_mutation
      json = response.parsed_body
      err = json['errors']&.first

      expect(err).to be_present
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(err['path']).to eq(['addTagToPhoto'])
      expect(json.dig('data', 'addTagToPhoto')).to be_nil
    end
  end

  context 'when the photo does not exist' do
    let(:photo_slug) { 'nonexistent-photo' }

    it 'returns an error' do
      post_mutation
      expect(first_error_message(response)).to eq('Photo not found')
    end
  end

  context 'when the tag name is empty' do
    let(:tag_name) { ' ' }

    it 'returns an error' do
      post_mutation
      expect(first_error_message(response)).to eq('Tag name cannot be empty')
    end
  end

  context 'when the user is logged in' do
    before do
      sign_in(photo.user)
    end

    it 'adds a tag to the photo and it is normalized' do
      post_mutation
      response_photo = data_dig(response, 'addTagToPhoto', 'photo')
      expect(response_photo['id']).to eq(photo.slug)
      expect(response_photo['userTags']).to include(
        'id' => anything,
        'name' => normalized_tag_name
      )
    end

    it 'does not add duplicate tags' do
      photo.tag_list.add(normalized_tag_name)
      photo.save!

      post_mutation
      response_photo = data_dig(response, 'addTagToPhoto', 'photo')
      expect(response_photo['userTags'].count { |tag| tag['name'] == normalized_tag_name }).to eq(1)
    end

    context 'when the tag cannot be found or created' do
      before do
        allow(ActsAsTaggableOn::Tag).to receive(:find_by).with(name: normalized_tag_name).and_return(nil)
      end

      it 'returns an error' do
        post_mutation
        expect(first_error_message(response)).to eq("Failed to find or create tag: #{normalized_tag_name}")
      end
    end
  end
end
