class RenameFlickrIdToSerialNumber < ActiveRecord::Migration[6.0]
  def change
    rename_column :photos, :flickr_id, :serial_number
  end
end
