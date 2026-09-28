# frozen_string_literal: true

# Every text search is a sequential scan today; there is no index on
# photos.tsv. labels(name) backs the advanced search's label-name
# autocomplete (#1101).
class AddPhotoSearchIndexes < ActiveRecord::Migration[8.1]
  def up
    execute 'CREATE INDEX index_photos_on_tsv ON photos USING gin (tsv)'
    add_index :labels, :name
  end

  def down
    remove_index :labels, :name
    remove_index :photos, name: 'index_photos_on_tsv'
  end
end
