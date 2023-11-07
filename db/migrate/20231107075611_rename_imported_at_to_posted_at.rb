class RenameImportedAtToPostedAt < ActiveRecord::Migration[7.0]
  def change
    rename_column :photos, :imported_at, :posted_at
  end
end
