# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'relatedTags Query', type: :request do
  subject(:post_query) { post '/graphql', params: { query: query, variables: variables.to_json } }

  let(:maramures)  { ActsAsTaggableOn::Tag.find_or_create_by!(name: 'maramures') }
  let(:baia_mare)  { ActsAsTaggableOn::Tag.find_or_create_by!(name: 'baia mare') }

  let!(:flickr_source) { TaggingSource.find_or_create_by!(name: 'Flickr') }

  def tag_user(photo, names)
    photo.tag_list.add(names)
    photo.save!
  end

  def tag_flickr(photo, names)
    flickr_source.tag(photo, with: Array(names).join(','), on: :tags)
    photo.save!
  end

  before do
    # Build co-occurrence:
    # P1: romania + maramures
    photo_1 = create(:photo)
    tag_user(photo_1, %w[romania maramures])

    # P2: romania + maramures (Flickr source)
    photo_2 = create(:photo)
    tag_flickr(photo_2, %w[romania maramures])

    # P3: romania + maramures + baia mare
    photo_3 = create(:photo)
    tag_user(photo_3, ['romania', 'maramures', 'baia mare'])

    # P4: baia mare + maramures
    photo_4 = create(:photo)
    tag_user(photo_4, ['baia mare', 'maramures'])

    # Rekognition tags should be excluded from computation
    TaggingSource.find_or_create_by!(name: 'Rekognition').tap do |src|
      noise = create(:photo)
      src.tag(noise, with: 'romania,maramures,baia mare', on: :tags)
      noise.save!
    end

    # Compute precomputed relations with relaxed thresholds for test robustness
    PrecomputeRelatedTagsJob.perform_now(min_support: 1, min_confidence: 0.0)
  end

  context 'with single-tag input (root query)' do
    let(:query) do
      <<~GQL
        query($ids: [ID!]!, $limit: Int, $minSupport: Int, $minConfidence: Float) {
          relatedTags(ids: $ids, limit: $limit, minSupport: $minSupport, minConfidence: $minConfidence) {
            id
            name
          }
        }
      GQL
    end

    let(:variables) { { ids: [maramures.slug], limit: 10, minSupport: 1, minConfidence: 0.0 } }

    it 'suggests romania for maramures' do
      post_query
      expect(response).to have_http_status(:ok)
      # Debug: print response when field is missing
      puts "GraphQL response body (single-tag): #{response.body}" if data_dig(response, 'relatedTags').nil?
      names = data_dig(response, 'relatedTags').pluck('name')
      expect(names).to include('romania')
    end
  end

  context 'with multi-tag input (root query)' do
    let(:query) do
      <<~GQL
        query($ids: [ID!]!, $limit: Int, $minSupport: Int, $minConfidence: Float) {
          relatedTags(ids: $ids, limit: $limit, minSupport: $minSupport, minConfidence: $minConfidence) {
            id
            name
          }
        }
      GQL
    end

    let(:variables) { { ids: [baia_mare.slug, maramures.slug], limit: 10, minSupport: 1, minConfidence: 0.0 } }

    it 'suggests romania for {baia mare, maramures}' do
      post_query
      expect(response).to have_http_status(:ok)
      # Debug: print response when field is missing
      puts "GraphQL response body (multi-tag): #{response.body}" if data_dig(response, 'relatedTags').nil?
      names = data_dig(response, 'relatedTags').pluck('name')
      expect(names).to include('romania')
    end
  end

  context 'with Tag.relatedTags field' do
    let(:query) do
      <<~GQL
        query($id: ID!) {
          tag(id: $id) {
            id
            name
            relatedTags(limit: 10) {
              id
              name
            }
          }
        }
      GQL
    end

    let(:variables) { { id: maramures.slug } }

    it 'suggests romania on Tag.relatedTags for maramures' do
      post_query
      expect(response).to have_http_status(:ok)
      names = data_dig(response, 'tag', 'relatedTags').pluck('name')
      expect(names).to include('romania')
    end
  end
end
