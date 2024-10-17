# frozen_string_literal: true

# == Schema Information
#
# Table name: flickr_users
#
#  id                    :bigint           not null, primary key
#  description           :text
#  iconfarm              :string
#  iconserver            :string
#  is_deleted            :boolean
#  location              :string
#  nsid                  :string
#  photos_count          :integer
#  photos_firstdate      :integer
#  photos_firstdatetaken :string
#  photosurl             :string
#  profileurl            :string
#  realname              :string
#  timezone_label        :string
#  timezone_offset       :string
#  username              :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  timezone_id           :string
#
FactoryBot.define do
  factory :flickr_user do
    description { Faker::Lorem.sentence }
    iconfarm { Faker::Number.number(digits: 2) }
    iconserver { Faker::Number.number(digits: 2) }
    is_deleted { false }
    location { Faker::Address.city }
    sequence(:nsid) { |n| "12345#{n}" }
    photos_count { Faker::Number.number(digits: 3) }
    photos_firstdate { Faker::Date.between(from: 2.years.ago, to: Date.today).to_time.to_i }
    photos_firstdatetaken { Faker::Date.between(from: 2.years.ago, to: Date.today).to_s }
    photosurl { Faker::Internet.url }
    profileurl { Faker::Internet.url }
    realname { Faker::Name.name }
    timezone_label { Faker::Address.time_zone }
    timezone_offset { Faker::Number.number(digits: 2) }
    timezone_id { Faker::Address.time_zone }
    username { Faker::Internet.username }
  end
end
