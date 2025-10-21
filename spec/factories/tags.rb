FactoryBot.define do
  factory :tag, class: ActsAsTaggableOn::Tag do
    sequence(:name) { |n| "#{Faker::Lorem.word.downcase}-#{n}" }

    trait :with_prefix do
      sequence(:name) { |n| "prefix-#{Faker::Lorem.word.downcase}-#{n}" }
    end
  end
end
