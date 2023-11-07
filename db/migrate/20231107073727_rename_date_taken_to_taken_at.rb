class RenameDateTakenToTakenAt < ActiveRecord::Migration[7.0]
  def change
    rename_column :photos, :date_taken, :taken_at
    rename_column :photos, :date_taken_from_exif, :taken_at_from_exif
  end
end
