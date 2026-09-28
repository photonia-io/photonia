# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id               :bigint           not null, primary key
#  body             :text
#  body_html        :text
#  commentable_type :string           not null
#  flickr_link      :string
#  serial_number    :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  commentable_id   :bigint           not null
#  flickr_user_id   :bigint
#  parent_id        :bigint
#  user_id          :bigint
#
# Indexes
#
#  index_comments_on_commentable     (commentable_type,commentable_id)
#  index_comments_on_flickr_user_id  (flickr_user_id)
#  index_comments_on_parent_id       (parent_id)
#  index_comments_on_serial_number   (serial_number) UNIQUE
#  index_comments_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (flickr_user_id => flickr_users.id)
#  fk_rails_...  (parent_id => comments.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Comment do
  it 'has a valid factory (with photo)' do
    expect(build(:comment, :with_photo)).to be_valid
  end

  it 'has a valid factory (with album)' do
    expect(build(:comment, :with_album)).to be_valid
  end

  describe 'validations' do
    it 'is invalid without a body' do
      expect(build(:comment, :with_photo, body: nil)).not_to be_valid
    end

    it 'is invalid without a user or a Flickr user' do
      expect(build(:comment, :with_photo, user: nil, flickr_user: nil)).not_to be_valid
    end

    it 'is valid with only a Flickr user' do
      expect(build(:comment, :with_photo, :with_flickr_user, user: nil)).to be_valid
    end

    context 'with a parent' do
      it 'is invalid when the parent is itself a reply' do
        photo = create(:photo)
        grandparent = create(:comment, commentable: photo)
        parent = create(:comment, commentable: photo, parent: grandparent)

        reply = build(:comment, commentable: photo, parent: parent)

        expect(reply).not_to be_valid
        expect(reply.errors[:parent]).to include('must be a top-level comment')
      end

      it 'is invalid when the parent belongs to a different commentable' do
        parent = create(:comment, :with_photo)
        reply = build(:comment, :with_photo, parent: parent)

        expect(reply).not_to be_valid
        expect(reply.errors[:parent]).to include('must belong to the same photo or album')
      end

      it 'is valid when the parent is top-level and shares the commentable' do
        photo = create(:photo)
        parent = create(:comment, commentable: photo)
        reply = build(:comment, commentable: photo, parent: parent)

        expect(reply).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to a commentable' do
      association = described_class.reflect_on_association(:commentable)
      expect(association.macro).to eq :belongs_to
    end

    it 'resolves its commentable even when the photo is private' do
      photo = create(:photo, privacy: :private)
      comment = create(:comment, commentable: photo)

      expect(Comment.find(comment.id).commentable).to eq(photo)
    end

    it 'resolves its commentable even when the album is private' do
      album = create(:album, privacy: :private)
      comment = create(:comment, commentable: album)

      expect(Comment.find(comment.id).commentable).to eq(album)
    end

    it 'has many replies, ordered oldest first' do
      photo = create(:photo)
      parent = create(:comment, commentable: photo)
      second_reply = create(:comment, commentable: photo, parent: parent, created_at: 1.hour.from_now)
      first_reply = create(:comment, commentable: photo, parent: parent, created_at: 2.hours.ago)

      expect(parent.reload.replies).to eq([first_reply, second_reply])
    end

    it 'destroys its replies when destroyed' do
      photo = create(:photo)
      parent = create(:comment, commentable: photo)
      reply = create(:comment, commentable: photo, parent: parent)

      parent.destroy

      expect(Comment.where(id: reply.id)).not_to exist
    end
  end

  describe '.top_level' do
    it 'excludes replies' do
      photo = create(:photo)
      parent = create(:comment, commentable: photo)
      create(:comment, commentable: photo, parent: parent)

      expect(Comment.top_level).to contain_exactly(parent)
    end
  end

  describe '#top_level?' do
    it 'is true without a parent' do
      expect(build(:comment, :with_photo).top_level?).to be true
    end

    it 'is false with a parent' do
      parent = create(:comment, :with_photo)
      expect(build(:comment, commentable: parent.commentable, parent: parent).top_level?).to be false
    end
  end

  describe 'callbacks' do
    it 'sets body_html before saving' do
      comment = create(:comment, :with_photo, body: 'This is a **test**')
      expect(comment.body_html).to eq '<p>This is a <strong>test</strong></p>'
    end
  end

  it_behaves_like 'it has trackable body', model: :comment, commentable_type: :photo
  it_behaves_like 'it has trackable body', model: :comment, commentable_type: :album
end
