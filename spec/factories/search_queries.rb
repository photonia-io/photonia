# frozen_string_literal: true

# == Schema Information
#
# Table name: search_queries
#
#  id               :bigint           not null, primary key
#  filters          :jsonb
#  normalized_query :string
#  query            :text
#  results_count    :integer          default(0), not null
#  session_hash     :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint
#
# Indexes
#
#  index_search_queries_on_created_at        (created_at)
#  index_search_queries_on_normalized_query  (normalized_query text_pattern_ops)
#  index_search_queries_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :search_query do
    query { 'lake' }
    results_count { 3 }
    session_hash { SecureRandom.hex(16) }
  end
end
