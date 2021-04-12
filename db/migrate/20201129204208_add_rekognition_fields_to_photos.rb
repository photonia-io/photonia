# frozen_string_literal: true

class AddRekognitionFieldsToPhotos < ActiveRecord::Migration[6.0]
  def change
    add_column :photos, :rekognition_response, :jsonb
    add_index :photos, :rekognition_response, using: :gin
  end
end
