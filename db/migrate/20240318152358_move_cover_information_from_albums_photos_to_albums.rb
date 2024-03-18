class MoveCoverInformationFromAlbumsPhotosToAlbums < ActiveRecord::Migration[7.1]
  def up
    AlbumsPhoto.all.each do |ap|
      if ap.cover
        puts 'cover!'
        Album.update(ap.album_id, user_cover_photo_id: ap.photo_id)
      end
    end
  end

  def down
    # no-op
  end
end
