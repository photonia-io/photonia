# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'createComment Mutation', type: :request do
  include Devise::Test::IntegrationHelpers
  include_context 'with auth actors'

  subject(:post_mutation) { post '/graphql', params: { query: query } }

  def build_query(commentable_type:, commentable_id:, body: 'Nice one!', parent_id: nil)
    parent_line = parent_id ? "parentId: \"#{parent_id}\"" : ''

    <<~GQL
      mutation {
        createComment(
          commentableType: "#{commentable_type}"
          commentableId: "#{commentable_id}"
          body: "#{body}"
          #{parent_line}
        ) {
          id
          body
          author { id }
        }
      }
    GQL
  end

  before { allow(UserMailer).to receive_message_chain(:with, :new_comment, :deliver_later) }

  context 'when the user is not logged in' do
    let(:photo) { create(:photo, user: owner) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug) }

    it 'returns NOT_FOUND and creates no comment' do
      expect { post_mutation }.not_to change(Comment, :count)

      err = response.parsed_body['errors'].first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when a stranger comments on a private photo' do
    let(:photo) { create(:photo, user: owner, privacy: :private) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug) }

    before { sign_in(stranger) }

    it 'returns NOT_FOUND' do
      post_mutation
      err = response.parsed_body['errors'].first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when the user is disabled' do
    let(:photo) { create(:photo, user: owner) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug) }

    before { sign_in(create(:user, disabled: true)) }

    it 'returns NOT_FOUND' do
      post_mutation
      err = response.parsed_body['errors'].first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when commenting is disabled globally' do
    let(:photo) { create(:photo, user: owner) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug) }

    before do
      Setting.commenting_enabled = false
      sign_in(stranger)
    end

    it 'returns a "Commenting is disabled" error' do
      post_mutation
      expect(first_error_message(response)).to eq('Commenting is disabled')
    end
  end

  context 'when photo commenting is disabled' do
    let(:photo) { create(:photo, user: owner) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug) }

    before do
      Setting.photo_commenting_enabled = false
      sign_in(stranger)
    end

    it 'returns a "Commenting is disabled" error, even with the general switch on' do
      post_mutation
      expect(first_error_message(response)).to eq('Commenting is disabled')
    end
  end

  context 'when commenting on an album with album commenting off (the default)' do
    let(:album) { create(:album, user: owner) }
    let(:query) { build_query(commentable_type: 'Album', commentable_id: album.slug) }

    before { sign_in(stranger) }

    it 'returns a "Commenting is disabled" error, even with the general switch on' do
      expect { post_mutation }.not_to change(Comment, :count)
      expect(first_error_message(response)).to eq('Commenting is disabled')
    end
  end

  context 'with an invalid commentable type' do
    let(:photo) { create(:photo, user: owner) }
    let(:query) { build_query(commentable_type: 'User', commentable_id: photo.slug) }

    before { sign_in(stranger) }

    it 'returns an "Invalid commentable type" error' do
      post_mutation
      expect(first_error_message(response)).to eq('Invalid commentable type')
    end
  end

  context 'when the owner comments on their own photo' do
    let(:photo) { create(:photo, user: owner) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug) }

    before { sign_in(owner) }

    it 'creates the comment and does not notify (no self-notification)' do
      post_mutation
      comment = data_dig(response, 'createComment')

      expect(comment['body']).to eq('Nice one!')
      expect(comment['id']).to eq(Comment.last.serial_number.to_s)
      expect(UserMailer).not_to have_received(:with)
    end
  end

  context 'when a stranger comments on a public photo' do
    let(:photo) { create(:photo, user: owner) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug) }

    before { sign_in(stranger) }

    it 'creates the comment and notifies the owner' do
      post_mutation
      comment = data_dig(response, 'createComment')

      expect(comment['author']['id']).to eq(stranger.slug)
      expect(UserMailer).to have_received(:with).with(comment: an_instance_of(Comment))
    end
  end

  context 'when a stranger comments on a public album' do
    let(:album) { create(:album, user: owner) }
    let(:query) { build_query(commentable_type: 'Album', commentable_id: album.slug) }

    before do
      Setting.album_commenting_enabled = true
      sign_in(stranger)
    end

    it 'creates the comment on the album' do
      expect { post_mutation }.to change(Comment, :count).by(1)
      expect(Comment.last.commentable).to eq(album)
    end
  end

  context 'when replying to a top-level comment' do
    let(:photo) { create(:photo, user: owner) }
    let!(:parent) { create(:comment, commentable: photo, user: owner) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug, parent_id: parent.serial_number) }

    before { sign_in(stranger) }

    it 'creates the reply' do
      post_mutation
      expect(Comment.last.parent).to eq(parent)
    end
  end

  context 'when replying to a reply' do
    let(:photo) { create(:photo, user: owner) }
    let(:parent) { create(:comment, commentable: photo, user: owner) }
    let!(:reply) { create(:comment, commentable: photo, user: owner, parent: parent) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug, parent_id: reply.serial_number) }

    before { sign_in(stranger) }

    it 'returns NOT_FOUND rather than creating a nested reply' do
      expect { post_mutation }.not_to change(Comment, :count)

      err = response.parsed_body['errors'].first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end

  context 'when the parent belongs to a different commentable' do
    let(:photo) { create(:photo, user: owner) }
    let(:other_photo) { create(:photo) }
    let!(:parent) { create(:comment, commentable: other_photo) }
    let(:query) { build_query(commentable_type: 'Photo', commentable_id: photo.slug, parent_id: parent.serial_number) }

    before { sign_in(stranger) }

    it 'returns NOT_FOUND' do
      expect { post_mutation }.not_to change(Comment, :count)

      err = response.parsed_body['errors'].first
      expect(err.dig('extensions', 'code')).to eq('NOT_FOUND')
    end
  end
end
