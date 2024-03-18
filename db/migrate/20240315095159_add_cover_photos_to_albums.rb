class AddCoverPhotosToAlbums < ActiveRecord::Migration[7.1]
  def change
    add_reference :albums, :public_cover_photo
    add_reference :albums, :user_cover_photo
  end
end
