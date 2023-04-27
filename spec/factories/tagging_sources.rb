# frozen_string_literal: true

# == Schema Information
#
# Table name: tagging_sources
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :tagging_source do
    name { Faker::Lorem.word }
  end
end
