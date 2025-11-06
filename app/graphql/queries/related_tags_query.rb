# frozen_string_literal: true

module Queries
  # Related Tags Query
  # Usage:
  #   query($ids: [ID!]!, $limit: Int = 10, $minSupport: Int = 2, $minConfidence: Float = 0.3) {
  #     relatedTags(ids: $ids, limit: $limit, minSupport: $minSupport, minConfidence: $minConfidence) {
  #       id
  #       name
  #     }
  #   }
  class RelatedTagsQuery < BaseQuery
    description 'Suggest related tags based on co-occurrence across public photos (user + Flickr tags, excludes Rekognition)'

    type [Types::TagType], null: false

    argument :ids, [ID], 'Tag slugs to base the suggestion on (single or multi-tag)', required: true
    argument :limit, Integer, 'Max number of suggestions to return', required: false, default_value: 10
    argument :min_confidence, Float, 'Minimum confidence threshold for directed relation A -> B', required: false, default_value: 0.3
    argument :min_support, Integer, 'Minimum co-occurrence count between tag pairs', required: false, default_value: 2

    def resolve(ids:, limit:, min_support:, min_confidence:)
      slugs = Array(ids).map(&:to_s).reject(&:blank?)
      return [] if slugs.empty?

      # Resolve slugs -> tag ids (do not expose DB ids)
      # Note: friendly_id cannot find multiple at once, use where(slug: ...) per project rules.
      source_tags = ActsAsTaggableOn::Tag.where(slug: slugs).to_a
      return [] if source_tags.empty?

      from_ids = source_tags.map(&:id)

      # Build an aggregated intersection over all input tags:
      #  - Apply thresholds (support/confidence)
      #  - Exclude self suggestions
      #  - Group by candidate tag_id_to, require presence from all inputs
      #  - Score by SUM(confidence), tie-break by MIN(confidence) then SUM(support)
      rel = RelatedTag
            .with_thresholds(min_support:, min_confidence:)
            .where(tag_id_from: from_ids)
            .where.not(tag_id_to: from_ids)
            .group(:tag_id_to)
            .select(
              'tag_id_to',
              'SUM(confidence) AS sum_confidence',
              'MIN(confidence) AS min_confidence',
              'SUM(support) AS sum_support',
              'COUNT(DISTINCT tag_id_from) AS from_count'
            )
            .having('COUNT(DISTINCT tag_id_from) = ?', from_ids.length)
            .order(Arel.sql('SUM(confidence) DESC, MIN(confidence) DESC, SUM(support) DESC, tag_id_to ASC'))
            .limit(limit)

      ordered_tag_ids = rel.pluck('tag_id_to')
      return [] if ordered_tag_ids.empty?

      tags_by_id = ActsAsTaggableOn::Tag.where(id: ordered_tag_ids).index_by(&:id)
      ordered_tag_ids.map { |tid| tags_by_id[tid] }.compact
    end
  end
end
