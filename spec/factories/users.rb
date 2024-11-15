# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  admin               :boolean          default(FALSE)
#  display_name        :string
#  email               :string           default(""), not null
#  encrypted_password  :string           default(""), not null
#  first_name          :string
#  jti                 :string
#  last_name           :string
#  remember_created_at :datetime
#  serial_number       :bigint
#  signup_provider     :string           default("local"), not null
#  slug                :string
#  timezone            :string           default("UTC"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_jti    (jti) UNIQUE
#
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
  end
end
