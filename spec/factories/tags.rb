FactoryBot.define do
  factory :tag, class: ActsAsTaggableOn::Tag do
    name { Faker::Lorem.word.downcase }
  end
end
