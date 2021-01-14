# frozen_string_literal: true

# Creates the albums table
class CreateAlbums < ActiveRecord::Migration[6.1]
  def change
    create_table :albums do |t|
      t.string :slug

      t.string :title
      t.text :description
      t.bigint :serial_number
      t.integer :flickr_views

      t.timestamps
    end
  end
end
