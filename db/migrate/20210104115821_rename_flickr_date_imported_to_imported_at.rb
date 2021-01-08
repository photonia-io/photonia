class RenameFlickrDateImportedToImportedAt < ActiveRecord::Migration[6.0]
  def change
    rename_column :photos, :flickr_date_imported, :imported_at
  end
end
