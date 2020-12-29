class AddTsvToPhotos < ActiveRecord::Migration[6.0]
  def change
    add_column :photos, :tsv, :tsvector
  end
end
