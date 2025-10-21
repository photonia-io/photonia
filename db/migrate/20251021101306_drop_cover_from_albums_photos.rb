# frozen_string_literal: true

# migration to drop the 'cover' column from albums_photos table
class DropCoverFromAlbumsPhotos < ActiveRecord::Migration[7.2]
  def change
    remove_column :albums_photos, :cover, :boolean, default: false, null: true
  end
end
