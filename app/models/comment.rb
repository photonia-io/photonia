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
class Comment < ApplicationRecord
  include SerialNumberSetter

  before_validation :set_serial_number, prepend: true

  include HtmlBodyable
  include TrackableBody

  # Photo/Album default-scope to public records, so a plain association read
  # can't see a comment's own commentable when it's private.
  belongs_to :commentable, -> { unscope(where: :privacy) }, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :flickr_user, optional: true
  belongs_to :parent, class_name: 'Comment', optional: true, inverse_of: :replies
  has_many :replies, -> { order(created_at: :asc) }, class_name: 'Comment',
                                                     foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  scope :top_level, -> { where(parent_id: nil) }

  validates :body, presence: true
  validate :author_present
  validate :parent_is_valid, if: :parent

  def top_level?
    parent_id.nil?
  end

  private

  def author_present
    errors.add(:base, 'must have a user or a Flickr user') if user.blank? && flickr_user.blank?
  end

  def parent_is_valid
    errors.add(:parent, 'must be a top-level comment') unless parent.top_level?
    return if parent.commentable_type == commentable_type && parent.commentable_id == commentable_id

    errors.add(:parent, 'must belong to the same photo or album')
  end
end
