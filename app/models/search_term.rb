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
# A word/lexeme drawn nightly from public photos' searchable text, for
# prefix-matched suggestions (PrecomputeSearchTermsJob). Read-only: never
# create/update a row directly, the job replaces the whole table.
class SearchTerm < ApplicationRecord
  validates :term, presence: true, uniqueness: true
  validates :photos_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
