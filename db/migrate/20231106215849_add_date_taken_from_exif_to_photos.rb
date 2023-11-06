class AddDateTakenFromExifToPhotos < ActiveRecord::Migration[7.0]
  def change
    add_column :photos, :date_taken_from_exif, :boolean, default: false
  end
end
