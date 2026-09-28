# frozen_string_literal: true

# Logs every submitted search (navbar and advanced) for suggestions and
# analytics. See #1101.
class CreateSearchQueries < ActiveRecord::Migration[8.1]
  def up
    create_table :search_queries do |t|
      t.text :query
      t.string :normalized_query
      t.jsonb :filters
      t.integer :results_count, null: false, default: 0
      t.references :user, foreign_key: true, null: true
      t.string :session_hash

      t.timestamps
    end

    add_index :search_queries, :created_at

    execute <<~SQL.squish
      CREATE INDEX index_search_queries_on_normalized_query
      ON search_queries (normalized_query text_pattern_ops)
    SQL
  end

  def down
    remove_index :search_queries, name: 'index_search_queries_on_normalized_query'
    drop_table :search_queries
  end
end
