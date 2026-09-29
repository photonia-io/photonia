# frozen_string_literal: true

# == Schema Information
#
# Table name: search_terms
#
#  id           :bigint           not null, primary key
#  photos_count :integer          default(0), not null
#  term         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_search_terms_on_term  (term text_pattern_ops) UNIQUE
#
FactoryBot.define do
  factory :search_term do
    sequence(:term) { |n| "term#{n}" }
    photos_count { 1 }
  end
end
