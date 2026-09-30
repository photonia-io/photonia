# frozen_string_literal: true

require 'rails_helper'

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
RSpec.describe SearchTerm do
  it 'has a valid factory' do
    expect(build(:search_term)).to be_valid
  end

  it 'requires a term' do
    expect(build(:search_term, term: nil)).not_to be_valid
  end

  it 'requires a unique term' do
    create(:search_term, term: 'lake')

    expect(build(:search_term, term: 'lake')).not_to be_valid
  end

  it 'requires a non-negative photos_count' do
    expect(build(:search_term, photos_count: -1)).not_to be_valid
  end
end
