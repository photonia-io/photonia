# frozen_string_literal: true

# Splits "processed" into pipeline stages (labeling, then derivatives), and
# adds a terminal-failure marker for a permanently failed Rekognition job.
class AddProcessingStagesToPhotos < ActiveRecord::Migration[7.2]
  def up
    change_table :photos, bulk: true do |t|
      t.datetime :labeled_at
      t.datetime :processing_failed_at
    end

    execute 'UPDATE photos SET labeled_at = created_at WHERE processed_at IS NOT NULL'
  end

  def down
    change_table :photos, bulk: true do |t|
      t.remove :labeled_at, :processing_failed_at
    end
  end
end
