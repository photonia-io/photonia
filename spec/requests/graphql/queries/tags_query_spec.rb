# frozen_string_literal: true

require 'rails_helper'

describe 'tags Query', type: :request do
  subject(:post_query) { post '/graphql', params: { query: query } }

  let(:flickr_tags) { build_list(:tag, 5) }
  let(:rekognition_tags) { build_list(:tag, 10) }
  let(:flickr_tag_list) { flickr_tags.join(',') }
  let(:rekognition_tag_list) { rekognition_tags.join(',') }
  let(:flickr_tagging_source) { TaggingSource.find_by(name: 'Flickr') }
  let(:rekognition_tagging_source) { TaggingSource.find_by(name: 'Rekognition') }
  let(:photo) { create(:photo) }

  before do
    flickr_tagging_source.tag(photo, with: flickr_tag_list, on: :tags)
    rekognition_tagging_source.tag(photo, with: rekognition_tag_list, on: :tags)
  end

  describe 'without parameters' do
    let(:query) do
      <<~GQL
        query {
          tags {
            id
            name
            taggingsCount
          }
        }
      GQL
    end

    it 'returns user tags' do
      post_query

      parsed_body = response.parsed_body
      response_tags = parsed_body['data']['tags']

      expect(response_tags.size).to eq(flickr_tags.size)
    end
  end

  describe 'with type=user' do
    let(:query) do
      <<~GQL
        query {
          tags(type: "user") {
            id
            name
            taggingsCount
          }
        }
      GQL
    end

    it 'returns user tags' do
      post_query

      parsed_body = response.parsed_body
      response_tags = parsed_body['data']['tags']

      expect(response_tags.size).to eq(flickr_tags.size)
    end
  end

  describe 'with type=machine' do
    let(:query) do
      <<~GQL
        query {
          tags(type: "machine") {
            id
            name
            taggingsCount
          }
        }
      GQL
    end

    it 'returns machine tags' do
      post_query

      parsed_body = response.parsed_body
      response_tags = parsed_body['data']['tags']

      expect(response_tags.size).to eq(rekognition_tags.size)
    end
  end

  describe 'with limit set' do
    let(:query) do
      <<~GQL
        query {
          tags(limit: 3) {
            id
            name
            taggingsCount
          }
        }
      GQL
    end

    it 'returns limited tags' do
      post_query

      parsed_body = response.parsed_body
      response_tags = parsed_body['data']['tags']

      expect(response_tags.size).to eq(3)
    end
  end
end
