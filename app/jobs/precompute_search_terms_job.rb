# frozen_string_literal: true

# Nightly precomputation of SearchTerm rows: words/lexemes drawn from public
# photos' title, description, tags and album titles via Postgres's ts_stat
# (the same lexeme extraction the tsv full-text index uses), so a suggestion
# is always something the search box can actually find. Fully replaces the
# table each run inside a transaction.
class PrecomputeSearchTermsJob < ApplicationJob
  queue_as :default

  SQL = <<~SQL.squish
    INSERT INTO search_terms (term, photos_count, created_at, updated_at)
    SELECT word, ndoc, NOW(), NOW()
    FROM ts_stat($stat$
      SELECT to_tsvector('simple', unaccent(
        coalesce(p.title, '') || ' ' || coalesce(p.description, '') || ' ' ||
        coalesce((
          SELECT string_agg(t.name, ' ')
          FROM taggings tg JOIN tags t ON t.id = tg.tag_id
          WHERE tg.taggable_id = p.id AND tg.taggable_type = 'Photo' AND tg.context = 'tags'
        ), '') || ' ' ||
        coalesce((
          SELECT string_agg(a.title, ' ')
          FROM albums_photos ap JOIN albums a ON a.id = ap.album_id
          WHERE ap.photo_id = p.id AND a.privacy = 'public'
        ), '')
      ))
      FROM photos p
      WHERE p.privacy = 'public'
    $stat$)
    WHERE length(word) >= 3 AND word !~ '^[0-9]+$' AND word !~ '[./@:]'
  SQL

  def perform
    connection = ActiveRecord::Base.connection
    connection.transaction do
      connection.exec_delete('DELETE FROM search_terms', 'SQL')
      connection.exec_query(SQL, 'SQL')
    end
  end
end
