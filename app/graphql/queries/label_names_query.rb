# frozen_string_literal: true

module Queries
  # Distinct Rekognition label names used by photos visible to the current
  # user, with counts - autocomplete for the advanced search's label filter
  # (#1101). Filters by photo_id IN (subquery), never joins(:photo), so
  # Photo's default (public-only) scope can't leak in.
  class LabelNamesQuery < BaseQuery
    description 'Find label names, prefix-matched and most used first'

    type [Types::LabelNameType], null: false

    argument :query, String, 'Prefix to filter label names by', required: false
    argument :limit, Integer, 'Max number of results', required: false

    DEFAULT_LIMIT = 10
    MAX_LIMIT = 100

    LabelName = Struct.new(:name, :count)

    def resolve(query: nil, limit: nil)
      base = Pundit.policy_scope(current_user, Photo.unscoped)
      relation = Label.where(photo_id: base.select(:id))
      relation = relation.where('name ILIKE ?', "#{sanitize_like(query)}%") if query.present?

      rows = relation.group(:name).order(Arel.sql('count_all DESC')).limit(effective_limit(limit)).count
      rows.map { |name, count| LabelName.new(name, count) }
    end

    private

    def effective_limit(limit)
      (limit || DEFAULT_LIMIT).clamp(0, MAX_LIMIT)
    end
  end
end
