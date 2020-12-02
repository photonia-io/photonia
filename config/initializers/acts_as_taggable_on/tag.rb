# frozen_string_literal: true

ActsAsTaggableOn::Tag.class_eval do
  extend FriendlyId
  friendly_id :name, use: :slugged

  scope :not_tagged_by_rekognition, -> { where.not(taggings: { tagger_id: 2 }) }
  scope :tagged_by_rekognition, -> { where(taggings: { tagger_id: 2 }) }
end
