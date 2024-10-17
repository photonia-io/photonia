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
FactoryBot.define do
  factory :comment do
    body { Faker::Lorem.paragraph }
    user

    trait :with_flickr_user do
      flickr_user
    end

    trait :with_photo do
      commentable { create(:photo) }
    end

    trait :with_album do
      commentable { create(:album) }
    end
  end
end
