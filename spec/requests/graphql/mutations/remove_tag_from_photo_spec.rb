# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'removeTagFromPhoto Mutation', type: :request do
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
      mutation RemoveTagFromPhoto($id: String!, $tagName: String!) {
        removeTagFromPhoto(id: $id, tagName: $tagName) {
          photo {
            id
            userTags {
              id
              name
            }
            machineTags {
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
    it 'raises Pundit::NotAuthorizedError' do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
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

    context 'when the user tag exists on the photo' do
      before do
        photo.tag_list.add(normalized_tag_name)
        photo.save!
      end

      it 'removes the tag from the photo' do
        post_mutation
        response_photo = data_dig(response, 'removeTagFromPhoto', 'photo')
        expect(response_photo['id']).to eq(photo.slug)
        expect(response_photo['userTags']).not_to include(
          hash_including('name' => normalized_tag_name)
        )
      end

      it 'returns the removed tag' do
        post_mutation
        response_tag = data_dig(response, 'removeTagFromPhoto', 'tag')
        expect(response_tag['name']).to eq(normalized_tag_name)
      end
    end

    context 'when the owned tag exists on the photo' do
      before do
        tagging_source = TaggingSource.find_or_create_by(name: 'CustomSource')
        tagging_source.tag(photo, with: normalized_tag_name, on: :tags)
        photo.save!
      end

      it 'removes the tag from the photo' do
        post_mutation
        response_photo = data_dig(response, 'removeTagFromPhoto', 'photo')
        expect(response_photo['id']).to eq(photo.slug)
        expect(response_photo['machineTags']).not_to include(
          hash_including('name' => normalized_tag_name)
        )
      end

      it 'returns the removed tag' do
        post_mutation
        response_tag = data_dig(response, 'removeTagFromPhoto', 'tag')
        expect(response_tag['name']).to eq(normalized_tag_name)
      end
    end

    context 'when the tag does not exist on the photo' do
      it 'returns an error' do
        post_mutation
        expect(first_error_message(response)).to eq("Tag '#{normalized_tag_name}' is not associated with this photo")
      end
    end

    context 'when the tag cannot be found after removal' do
      before do
        photo.tag_list.add(normalized_tag_name)
        photo.save!
        allow(ActsAsTaggableOn::Tag).to receive(:find_by).with(name: normalized_tag_name).and_return(nil)
      end

      it 'returns an error' do
        post_mutation
        expect(first_error_message(response)).to eq("Failed to find tag: #{normalized_tag_name}")
      end
    end
  end
end
