# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'deleteComment Mutation', type: :request do
  include Devise::Test::IntegrationHelpers
  include_context 'with auth actors'

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  let(:photo) { create(:photo, user: owner) }
  let(:author) { create(:user) }
  let!(:comment) { create(:comment, commentable: photo, user: author) }

  let(:query) do
    <<~GQL
      mutation {
        deleteComment(id: "#{comment.serial_number}") {
          id
        }
      }
    GQL
  end

  context 'when the author is signed in' do
    before { sign_in(author) }

    it 'deletes the comment' do
      expect { post_mutation }.to change(Comment, :count).by(-1)
      expect(Comment.where(id: comment.id)).not_to exist
    end
  end

  context "when the commentable's owner is signed in" do
    before { sign_in(owner) }

    it "deletes a stranger's comment" do
      expect { post_mutation }.to change(Comment, :count).by(-1)
    end
  end

  context 'when an admin is signed in' do
    before { sign_in(admin) }

    it 'deletes any comment' do
      expect { post_mutation }.to change(Comment, :count).by(-1)
    end
  end

  context 'when a stranger is signed in' do
    before { sign_in(stranger) }

    it 'returns NOT_FOUND and leaves the comment' do
      expect { post_mutation }.not_to change(Comment, :count)

      err = response.parsed_body['errors'].first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when signed out' do
    it 'returns NOT_FOUND' do
      expect { post_mutation }.not_to change(Comment, :count)

      err = response.parsed_body['errors'].first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when the comment has replies' do
    let!(:reply) { create(:comment, commentable: photo, parent: comment) }

    before { sign_in(author) }

    it 'deletes the replies too' do
      post_mutation
      expect(Comment.where(id: reply.id)).not_to exist
    end
  end
end
