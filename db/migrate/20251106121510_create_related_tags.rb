# frozen_string_literal: true

class CreateRelatedTags < ActiveRecord::Migration[7.2]
  ##
  # Creates the `related_tags` table to store association statistics between tags,
  # including support, confidence, lift, and jaccard, and adds the appropriate
  # indexes and foreign key constraints.
  #
  # Columns:
  # - `tag_id_from` (bigint, not null)
  # - `tag_id_to` (bigint, not null)
  # - `support` (integer, not null)
  # - `support_from` (integer, not null)
  # - `support_to` (integer, not null)
  # - `confidence` (float, not null)
  # - `lift` (float, not null)
  # - `jaccard` (float, not null)
  # - `created_at` and `updated_at` timestamps (not null)
  #
  # Indexes:
  # - unique composite index on `tag_id_from` and `tag_id_to`
  # - non-unique index on `tag_id_to`
  #
  # Foreign keys:
  # - `tag_id_from` → `tags.id`
  # - `tag_id_to` → `tags.id`
  def change
    create_table :related_tags do |t|
      t.bigint :tag_id_from, null: false
      t.bigint :tag_id_to, null: false
      t.integer :support, null: false
      t.integer :support_from, null: false
      t.integer :support_to, null: false
      t.float :confidence, null: false
      t.float :lift, null: false
      t.float :jaccard, null: false
      t.timestamps null: false
    end

    add_index :related_tags, %i[tag_id_from tag_id_to], unique: true
    add_index :related_tags, :tag_id_to
    add_foreign_key :related_tags, :tags, column: :tag_id_from
    add_foreign_key :related_tags, :tags, column: :tag_id_to
  end
end