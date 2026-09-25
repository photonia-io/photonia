# frozen_string_literal: true

# Breaks the single "processed" marker into pipeline stages, so the upload
# page can show what's actually happening (labeling/tagging vs. creating
# derivatives) instead of one opaque "processing" state, and so a permanent
# Rekognition failure has somewhere to record itself instead of leaving the
# row polling forever.
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
