# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id                       :bigint           not null, primary key
#  description              :text
#  description_html         :text
#  exif                     :jsonb
#  flickr_faves             :integer
#  flickr_impressions_count :integer          default(0), not null
#  flickr_json              :jsonb
#  flickr_original          :string
#  flickr_photopage         :string
#  image_data               :jsonb
#  impressions_count        :integer          default(0), not null
#  license                  :string
#  posted_at                :datetime
#  privacy                  :enum             default("public")
#  rekognition_response     :jsonb
#  scanned                  :boolean          default(FALSE), not null
#  serial_number            :bigint           not null
#  slug                     :string
#  taken_at                 :datetime
#  taken_at_approximate     :boolean          default(FALSE), not null
#  taken_at_precision       :string           default("minute"), not null
#  taken_at_source          :string           default("unknown"), not null
#  timezone                 :string           default("UTC"), not null
#  title                    :string
#  tsv                      :tsvector
#  user_thumbnail           :jsonb
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :bigint
#
# Indexes
#
#  index_photos_on_exif                  (exif) USING gin
#  index_photos_on_rekognition_response  (rekognition_response) USING gin
#  index_photos_on_slug                  (slug) UNIQUE
#  index_photos_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :photo do
    title { Faker::Lorem.sentence }
    description { Faker::Markdown.sandwich }
    user

    trait :with_taken_at do
      taken_at { Faker::Time.between(from: 1.year.ago, to: Time.zone.now) }
    end

    trait :with_partial_taken_at do
      taken_at { Time.zone.local(Faker::Number.between(from: 1900, to: 2020)) }
      taken_at_precision { 'year' }
      taken_at_source { 'user' }
    end

    trait :scanned do
      scanned { true }
    end

    trait :with_image do
      after(:build) do |photo|
        file_path = Rails.root.join('spec/support/images/zell-am-see-with-exif.jpg')
        photo.image = File.open(file_path)
      end
    end
  end
end
