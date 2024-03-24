class AddDescriptionHtmlToAlbums < ActiveRecord::Migration[7.1]
  def change
    add_column :albums, :description_html, :text
  end
end
