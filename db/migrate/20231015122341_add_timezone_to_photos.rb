class AddTimezoneToPhotos < ActiveRecord::Migration[7.0]
  def change
    add_column :photos, :timezone, :string, null: false, default: 'UTC'
  end
end
