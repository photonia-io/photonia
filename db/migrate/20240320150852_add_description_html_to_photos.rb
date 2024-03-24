class AddDescriptionHtmlToPhotos < ActiveRecord::Migration[7.1]
  def change
    add_column :photos, :description_html, :text
  end
end
