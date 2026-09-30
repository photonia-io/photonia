# frozen_string_literal: true

# Words/lexemes extracted nightly from public photos' searchable text
# (title, description, tags, album titles), for prefix-matched suggestions.
# Fully replaced on each run by PrecomputeSearchTermsJob, never written to
# directly otherwise.
class CreateSearchTerms < ActiveRecord::Migration[8.1]
  def change
    create_table :search_terms do |t|
      t.string :term, null: false
      t.integer :photos_count, null: false, default: 0
      t.timestamps
    end

    # text_pattern_ops so a prefix LIKE 'foo%' can use the index regardless
    # of the database's collation (plain btree only helps under C collation).
    add_index :search_terms, :term, unique: true, opclass: :text_pattern_ops
  end
end
