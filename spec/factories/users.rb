# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                         :bigint           not null, primary key
#  admin                      :boolean          default(FALSE)
#  created_from_facebook      :boolean          default(FALSE), not null
#  disabled                   :boolean          default(FALSE), not null
#  display_name               :string
#  email                      :string           default(""), not null
#  encrypted_password         :string           default(""), not null
#  facebook_confirmation_code :string
#  first_name                 :string
#  jti                        :string
#  last_name                  :string
#  remember_created_at        :datetime
#  serial_number              :bigint
#  signup_provider            :string           default("local"), not null
#  slug                       :string
#  timezone                   :string           default("UTC"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  facebook_user_id           :string
#
# Indexes
#
#  index_users_on_email                       (email) UNIQUE
#  index_users_on_facebook_confirmation_code  (facebook_confirmation_code) UNIQUE
#  index_users_on_facebook_user_id            (facebook_user_id) UNIQUE
#  index_users_on_jti                         (jti) UNIQUE
#
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }

    trait :uploader do
      after(:create) do |user|
        uploader_role = Role.find_by(symbol: 'uploader')
        user.roles << uploader_role
      end
    end
  end
end
