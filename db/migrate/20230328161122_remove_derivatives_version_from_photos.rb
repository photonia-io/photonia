class RemoveDerivativesVersionFromPhotos < ActiveRecord::Migration[7.0]
  def change
    remove_column :photos, :derivatives_version
  end
end
