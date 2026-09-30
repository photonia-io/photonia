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
# A logged search (navbar or advanced), used for suggestions and analytics.
class SearchQuery < ApplicationRecord
  belongs_to :user, optional: true

  before_validation :normalize_query

  # Never lets a logging failure break the search that triggered it.
  def self.record(query:, results_count:, user:, session_hash:, filters: nil)
    create!(query:, filters:, results_count:, user:, session_hash:)
  rescue StandardError => e
    Rails.logger.error "SearchQuery.record failed: #{e.message}"
    Sentry.capture_exception(e)
    nil
  end

  private

  def normalize_query
    self.normalized_query = query&.downcase&.squish.presence
  end
end
