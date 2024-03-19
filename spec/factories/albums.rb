# frozen_string_literal: true

# == Schema Information
#
# Table name: albums
#
#  id                       :bigint           not null, primary key
#  description              :text
#  flickr_impressions_count :integer          default(0), not null
#  impressions_count        :integer          default(0), not null
#  photos_count             :integer          default(0), not null
#  privacy                  :enum             default("public")
#  public_photos_count      :integer          default(0), not null
#  serial_number            :bigint
#  slug                     :string
#  title                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  public_cover_photo_id    :bigint
#  user_cover_photo_id      :bigint
#  user_id                  :bigint           default(1), not null
#
# Indexes
#
#  index_albums_on_public_cover_photo_id  (public_cover_photo_id)
#  index_albums_on_user_cover_photo_id    (user_cover_photo_id)
#  index_albums_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :album do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    flickr_impressions_count { Faker::Number.number(digits: 5) }
    user
  end
end
