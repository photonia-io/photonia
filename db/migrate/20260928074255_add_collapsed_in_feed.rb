# frozen_string_literal: true

# Lets an album collapse to a single feed entry (its cover), so a huge album
# (e.g. a race shoot) doesn't bury the photo feed. See #907.
class AddCollapsedInFeed < ActiveRecord::Migration[7.2]
  def up
    add_column :albums, :collapsed_in_feed, :boolean, null: false, default: false
    add_column :photos, :hidden_from_feed, :boolean, null: false, default: false

    execute <<~SQL.squish
      CREATE INDEX index_photos_on_posted_at_and_id_in_feed
      ON photos (posted_at, id) WHERE hidden_from_feed = false
    SQL
  end

  def down
    remove_index :photos, name: 'index_photos_on_posted_at_and_id_in_feed'
    remove_column :photos, :hidden_from_feed
    remove_column :albums, :collapsed_in_feed
  end
end
