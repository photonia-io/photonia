class AddPhotoCountsToAlbums < ActiveRecord::Migration[7.1]
  def change
    add_column :albums, :public_photos_count, :integer, null: false, default: 0
    add_column :albums, :photos_count, :integer, null: false, default: 0
  end
end
