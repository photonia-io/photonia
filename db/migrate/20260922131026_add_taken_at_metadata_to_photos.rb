# frozen_string_literal: true

# Splits the old taken_at_from_exif boolean into a source enum (exif/user/unknown)
# so a manually-entered date and a defaulted-to-upload-time date are distinguishable.
# Also adds precision (how much of the date is actually known) and two independent
# flags: approximate and scanned.
class AddTakenAtMetadataToPhotos < ActiveRecord::Migration[7.2]
  def up
    change_table :photos, bulk: true do |t|
      t.string :taken_at_precision, null: false, default: 'minute'
      t.string :taken_at_source, null: false, default: 'unknown'
      t.boolean :taken_at_approximate, null: false, default: false
      t.boolean :scanned, null: false, default: false
    end

    execute "UPDATE photos SET taken_at_source = 'exif' WHERE taken_at_from_exif"

    remove_column :photos, :taken_at_from_exif
  end

  def down
    add_column :photos, :taken_at_from_exif, :boolean, default: false

    execute "UPDATE photos SET taken_at_from_exif = true WHERE taken_at_source = 'exif'"

    change_table :photos, bulk: true do |t|
      t.remove :taken_at_precision, :taken_at_source, :taken_at_approximate, :scanned
    end
  end
end
