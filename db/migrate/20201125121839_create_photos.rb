class CreatePhotos < ActiveRecord::Migration[6.0]
  def change
    create_table :photos do |t|
      t.string   :slug

      t.string   :name
      t.text     :description
      t.datetime :date_taken
      t.string   :license
      t.jsonb    :exif

      t.string   :flickr_id
      t.integer  :flickr_views
      t.integer  :flickr_faves
      t.datetime :flickr_date_imported
      t.string   :flickr_photopage
      t.string   :flickr_original

      t.jsonb    :image_data
      t.jsonb    :flickr_json

      t.timestamps
    end

    add_index :photos, :slug, unique: true
    add_index :photos, :exif, using: :gin
  end
end
