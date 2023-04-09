# == Schema Information
#
# Table name: albums
#
#  id                :bigint           not null, primary key
#  description       :text
#  flickr_views      :integer
#  impressions_count :integer          default(0), not null
#  serial_number     :bigint
#  slug              :string
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :album do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    flickr_views { Faker::Number.number(digits: 5) }
  end
end
