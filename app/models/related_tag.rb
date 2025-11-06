# frozen_string_literal: true

# == Schema Information
#
# Table name: related_tags
#
#  id           :bigint           not null, primary key
#  confidence   :float            not null
#  jaccard      :float            not null
#  lift         :float            not null
#  support      :integer          not null
#  support_from :integer          not null
#  support_to   :integer          not null
#  tag_id_from  :bigint           not null
#  tag_id_to    :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_related_tags_on_tag_id_from_and_tag_id_to  (tag_id_from,tag_id_to) UNIQUE
#  index_related_tags_on_tag_id_to                  (tag_id_to)
#
# Foreign Keys
#
#  fk_rails_...  (tag_id_from => tags.id)
#  fk_rails_...  (tag_id_to => tags.id)
#
class RelatedTag < ApplicationRecord
  self.table_name = 'related_tags'

  belongs_to :from_tag, class_name: 'ActsAsTaggableOn::Tag', foreign_key: 'tag_id_from', optional: false
  belongs_to :to_tag, class_name: 'ActsAsTaggableOn::Tag', foreign_key: 'tag_id_to', optional: false

  validates :tag_id_from, :tag_id_to, :support, :support_from, :support_to, :confidence, :lift, :jaccard, presence: true
  validates :confidence, :lift, :jaccard, numericality: true
  validates :support, :support_from, :support_to, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :with_thresholds, lambda { |min_support: 2, min_confidence: 0.3|
    where('support >= ? AND confidence >= ?', min_support, min_confidence)
  }

  scope :ordered_for_suggestion, lambda {
    order(confidence: :desc, support: :desc, tag_id_to: :asc)
  }
end
