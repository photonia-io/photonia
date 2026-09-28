# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'updateComment Mutation', type: :request do
  include Devise::Test::IntegrationHelpers
  include_context 'with auth actors'

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:photo) { create(:photo, user: owner) }
  let(:author) { create(:user) }
  let(:comment) { create(:comment, commentable: photo, user: author, body: 'Original') }

  let(:query) do
    <<~GQL
      mutation {
        updateComment(id: "#{comment.serial_number}", body: "Edited body") {
          id
          body
          bodyEdited
        }
      }
    GQL
  end

  context 'when the author is signed in' do
    before { sign_in(author) }

    it 'updates the comment body' do
      post_mutation
      data = data_dig(response, 'updateComment')

      expect(data['body']).to eq('Edited body')
      expect(data['bodyEdited']).to be true
      expect(comment.reload.body).to eq('Edited body')
    end
  end

  context 'when a stranger is signed in' do
    before { sign_in(stranger) }

    it 'returns NOT_FOUND and leaves the comment unchanged' do
      post_mutation
      err = response.parsed_body['errors'].first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
      expect(comment.reload.body).to eq('Original')
    end
  end

  context "when the commentable's owner is signed in" do
    before { sign_in(owner) }

    it "returns NOT_FOUND - the owner may delete, but not edit, someone else's comment" do
      post_mutation
      err = response.parsed_body['errors'].first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when an admin is signed in' do
    before { sign_in(admin) }

    it "returns NOT_FOUND - admins may delete, but not edit, someone else's comment" do
      post_mutation
      err = response.parsed_body['errors'].first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when signed out' do
    it 'returns NOT_FOUND' do
      post_mutation
      err = response.parsed_body['errors'].first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'with an unknown comment id' do
    let(:query) do
      <<~GQL
        mutation {
          updateComment(id: "999999999", body: "Edited body") {
            id
          }
        }
      GQL
    end

    before { sign_in(author) }

    it 'returns NOT_FOUND' do
      post_mutation
      err = response.parsed_body['errors'].first

      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end
end
