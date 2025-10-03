# frozen_string_literal: true

# This migration adds an index on the tagger_id and tagger_type columns
# in the taggings table to improve query performance when filtering by tagger.
# The index is created concurrently to avoid locking the table during the operation.
class AddIndexOnTaggingsTagger < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index ActsAsTaggableOn.taggings_table,
              %i[tagger_id tagger_type],
              name: 'taggings_tagger_idx',
              algorithm: :concurrently
  end
end
