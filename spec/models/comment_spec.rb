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
#  user_id          :bigint
#
# Indexes
#
#  index_comments_on_commentable     (commentable_type,commentable_id)
#  index_comments_on_flickr_user_id  (flickr_user_id)
#  index_comments_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (flickr_user_id => flickr_users.id)
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
