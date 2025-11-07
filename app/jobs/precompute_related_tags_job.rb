# frozen_string_literal: true

class PrecomputeRelatedTagsJob < ApplicationJob
  queue_as :default

  # Compute directed related-tag metrics from public photos using user + Flickr tags (exclude Rekognition).
  # Thresholds:
  # - min_support: minimum co-occurrence count between two tags to be considered
  # - min_confidence: minimum confidence (support / support_from) for a directed relation A -> B
  #
  # This job fully refreshes the related_tags table in a transaction.
  #
  # Example:
  ##
  # Recomputes directed related-tag metrics for public photos and replaces the related_tags table.
  #
  # Performs a full recomputation inside a database transaction: clears existing related_tags rows,
  # computes co-occurrence and association metrics (support, confidence, lift, jaccard) from distinct
  # (photo, tag) pairs of public photos, excludes taggings from the TaggingSource named "Rekognition"
  # if present, generates two directed relations for each tag pair (A→B and B→A), and inserts the
  # directional rows that meet the provided thresholds.
  # @param [Integer] min_support - Minimum co-occurrence count required for a relation (defaults to 2).
  # @param [Float] min_confidence - Minimum confidence required for a relation (0.0..1.0, defaults to 0.3).
  def perform(min_support: 2, min_confidence: 0.3)
    min_support = min_support.to_i
    min_confidence = min_confidence.to_f

    rekognition_tagger_id = TaggingSource.find_by(name: 'Rekognition')&.id

    connection = ActiveRecord::Base.connection
    connection.transaction do
      # Clear previous results
      connection.exec_delete('DELETE FROM related_tags', 'SQL')

      # Build SQL for full recomputation using CTEs
      # Notes:
      # - We consider only public photos (privacy = 'public')
      # - We exclude Rekognition taggings by tagger_id
      # - We deduplicate (photo_id, tag_id) pairs to avoid duplicate taggings from different sources (e.g., Flickr + user)
      # - We compute pair co-occurrences and derive metrics: confidence, lift, jaccard
      # - We insert two directed rows for each undirected pair (A -> B and B -> A)
      sql = <<~SQL
        WITH
        photo_tags AS (
          SELECT DISTINCT p.id AS photo_id, t.tag_id
          FROM photos p
          JOIN taggings t
            ON t.taggable_id = p.id
           AND t.taggable_type = 'Photo'
           AND t.context = 'tags'
          WHERE p.privacy = 'public'
            AND (
              :rekognition_id IS NULL
              OR t.tagger_id IS NULL
              OR t.tagger_id <> :rekognition_id
            )
        ),
        tagged_photos AS (
          SELECT COUNT(DISTINCT photo_id) AS n FROM photo_tags
        ),
        tag_counts AS (
          SELECT tag_id, COUNT(*) AS cnt
          FROM photo_tags
          GROUP BY tag_id
        ),
        pair_counts AS (
          SELECT
            LEAST(t1.tag_id, t2.tag_id) AS tag_id_a,
            GREATEST(t1.tag_id, t2.tag_id) AS tag_id_b,
            COUNT(*) AS co_cnt
          FROM photo_tags t1
          JOIN photo_tags t2
            ON t1.photo_id = t2.photo_id
           AND t1.tag_id < t2.tag_id
          GROUP BY LEAST(t1.tag_id, t2.tag_id), GREATEST(t1.tag_id, t2.tag_id)
        ),
        metrics AS (
          SELECT
            pc.tag_id_a,
            pc.tag_id_b,
            pc.co_cnt,
            tca.cnt AS cnt_a,
            tcb.cnt AS cnt_b,
            tp.n AS total_photos
          FROM pair_counts pc
          JOIN tag_counts tca ON tca.tag_id = pc.tag_id_a
          JOIN tag_counts tcb ON tcb.tag_id = pc.tag_id_b
          CROSS JOIN tagged_photos tp
        ),
        directional AS (
          -- A -> B
          SELECT
            m.tag_id_a AS tag_id_from,
            m.tag_id_b AS tag_id_to,
            m.co_cnt     AS support,
            m.cnt_a      AS support_from,
            m.cnt_b      AS support_to,
            (m.co_cnt::float / m.cnt_a) AS confidence,
            -- lift = (co_cnt * N) / (cnt_a * cnt_b)
            (m.co_cnt::float * m.total_photos::float) / NULLIF((m.cnt_a::float * m.cnt_b::float), 0) AS lift,
            -- jaccard = co_cnt / (cnt_a + cnt_b - co_cnt)
            (m.co_cnt::float / NULLIF((m.cnt_a + m.cnt_b - m.co_cnt)::float, 0)) AS jaccard
          FROM metrics m

          UNION ALL

          -- B -> A
          SELECT
            m.tag_id_b AS tag_id_from,
            m.tag_id_a AS tag_id_to,
            m.co_cnt     AS support,
            m.cnt_b      AS support_from,
            m.cnt_a      AS support_to,
            (m.co_cnt::float / m.cnt_b) AS confidence,
            (m.co_cnt::float * m.total_photos::float) / NULLIF((m.cnt_a::float * m.cnt_b::float), 0) AS lift,
            (m.co_cnt::float / NULLIF((m.cnt_a + m.cnt_b - m.co_cnt)::float, 0)) AS jaccard
          FROM metrics m
        )
        INSERT INTO related_tags
          (tag_id_from, tag_id_to, support, support_from, support_to, confidence, lift, jaccard, created_at, updated_at)
        SELECT
          d.tag_id_from, d.tag_id_to, d.support, d.support_from, d.support_to, d.confidence, d.lift, d.jaccard,
          NOW(), NOW()
        FROM directional d
        WHERE d.support >= :min_support
          AND d.confidence >= :min_confidence
          AND d.tag_id_from <> d.tag_id_to
      SQL

      binds = {
        rekognition_id: rekognition_tagger_id,
        min_support: min_support,
        min_confidence: min_confidence
      }

      sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql, binds])
      connection.exec_query(sanitized_sql, 'SQL')
    end
  end
end
