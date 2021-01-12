# frozen_string_literal: true

# Creates the link table between albums and photos
class CreateAlbumsPhotos < ActiveRecord::Migration[6.1]
  def change
    create_table :albums_photos do |t|
      t.references :album, null: false, foreign_key: true
      t.references :photo, null: false, foreign_key: true
      t.boolean :cover, default: false
      t.integer :ordering

      t.timestamps
    end
  end
end
