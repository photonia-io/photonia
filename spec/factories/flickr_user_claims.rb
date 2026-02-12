# frozen_string_literal: true

# == Schema Information
#
# Table name: flickr_user_claims
#
#  id                :bigint           not null, primary key
#  approved_at       :datetime
#  claim_type        :string           not null
#  denied_at         :datetime
#  reason            :text
#  status            :string           default("pending"), not null
#  verification_code :string
#  verified_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  flickr_user_id    :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_flickr_user_claims_on_flickr_user_id              (flickr_user_id)
#  index_flickr_user_claims_on_status                      (status)
#  index_flickr_user_claims_on_user_id                     (user_id)
#  index_flickr_user_claims_on_user_id_and_flickr_user_id  (user_id,flickr_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (flickr_user_id => flickr_users.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :flickr_user_claim do
    user
    flickr_user
    claim_type { 'automatic' }
    status { 'pending' }
    verification_code { SecureRandom.alphanumeric(10) }

    trait :automatic do
      claim_type { 'automatic' }
      verification_code { SecureRandom.alphanumeric(10) }
    end

    trait :manual do
      claim_type { 'manual' }
      verification_code { nil }
      reason { Faker::Lorem.paragraph }
    end

    trait :approved do
      status { 'approved' }
      approved_at { Time.current }
    end

    trait :denied do
      status { 'denied' }
      denied_at { Time.current }
    end

    trait :verified do
      verified_at { Time.current }
    end
  end
end
