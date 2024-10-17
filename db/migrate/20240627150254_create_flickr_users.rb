class CreateFlickrUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :flickr_users do |t|
      t.string :nsid
      t.boolean :is_deleted, null: true
      t.string :iconserver, null: true
      t.string :iconfarm, null: true
      t.string :username, null: true
      t.string :realname, null: true
      t.string :location, null: true
      t.string :timezone_label, null: true
      t.string :timezone_offset, null: true
      t.string :timezone_id, null: true
      t.text :description, null: true
      t.string :photosurl, null: true
      t.string :profileurl, null: true
      t.string :photos_firstdatetaken, null: true
      t.integer :photos_firstdate, null: true
      t.integer :photos_count, null: true

      t.timestamps
    end
  end
end
