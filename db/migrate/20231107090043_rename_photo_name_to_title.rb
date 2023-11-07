class RenamePhotoNameToTitle < ActiveRecord::Migration[7.0]
  def change
    rename_column :photos, :name, :title
  end
end
