class AddDefaultLicenseToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :default_license, :string, default: nil
  end
end
