class AddSerialNumberAndSlugToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :serial_number, :bigint
    add_column :users, :slug, :string
  end
end
