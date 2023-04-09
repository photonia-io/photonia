# frozen_string_literal: true

# Monkeypatching ActsAsTaggableOn::Tag class
ActsAsTaggableOn::Tag.class_eval do
  include Impressionist::IsImpressionable
  is_impressionable counter_cache: true, unique: :session_hash

  extend FriendlyId
  friendly_id :name, use: :slugged

  scope :rekognition, lambda { |rekognition = false|
    if rekognition
      where(taggings: { tagger_id: 2 })
    else
      where.not(taggings: { tagger_id: 2 }).or(where(taggings: { tagger_id: nil }))
    end
  }

  def self.distinct_taggings_count(rekognition: false)
    joins(:taggings).distinct(:taggings_count).rekognition(rekognition)
  end

  def self.photonia_most_used(limit: 100, rekognition: false)
    distinct_taggings_count(rekognition: rekognition).most_used(limit)
  end

  def self.photonia_least_used(limit: 100, rekognition: false)
    distinct_taggings_count(rekognition: rekognition).least_used(limit)
  end
end
