# frozen_string_literal: true

require "rails_helper"

RSpec.describe "addTagToPhoto Mutation", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:photo) { create(:photo) }
  let(:tag_name) { " TestTag " }
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

  subject(:post_mutation) {
    post '/graphql',
    params: {
      query: query,
      variables: { id: photo.slug, tagName: tag_name }
    }
  }

  context "when the user is not logged in" do
    it "raises Pundit::NotAuthorizedError" do
      expect { post_mutation }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is logged in" do
    before do
      sign_in(photo.user)
    end

    it "adds a tag to the photo and it is normalized" do
      post_mutation
      json = JSON.parse(response.body)
      data = json['data']['addTagToPhoto']
      expect(data['photo']['id']).to eq(photo.slug)
      expect(data['photo']['userTags']).to include(
        'id' => anything,
        'name' => normalized_tag_name
      )
    end

    it "does not add duplicate tags" do
      photo.tag_list.add(normalized_tag_name)
      photo.save!

      post_mutation
      json = JSON.parse(response.body)
      data = json['data']['addTagToPhoto']

      expect(data['photo']['userTags'].count { |tag| tag['name'] == normalized_tag_name }).to eq(1)
    end
  end
end

