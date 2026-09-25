# frozen_string_literal: true

# Marks when a photo's upload pipeline (Rekognition tagging, then derivatives)
# finished, so the upload page can poll for it instead of guessing from
# image_data (an intelligent derivative doesn't always exist).
class AddProcessedAtToPhotos < ActiveRecord::Migration[7.2]
  def up
    add_column :photos, :processed_at, :datetime

    execute 'UPDATE photos SET processed_at = created_at'
  end

  def down
    remove_column :photos, :processed_at
  end
end
