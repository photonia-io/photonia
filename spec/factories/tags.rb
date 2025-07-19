FactoryBot.define do
  factory :tag, class: ActsAsTaggableOn::Tag do
    sequence(:name) { |n| "#{Faker::Lorem.word.downcase}-#{n}" }

    trait :with_prefix do
      name { "prefix-#{Faker::Lorem.word.downcase}" }
    end
  end
end
