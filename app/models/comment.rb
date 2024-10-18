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
class Comment < ApplicationRecord
  include SerialNumberSetter
  before_validation :set_serial_number, prepend: true

  include HtmlBodyable

  belongs_to :commentable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :flickr_user, optional: true

  validates :body, presence: true
end
