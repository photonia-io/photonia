# frozen_string_literal: true

class AddDefaultLicenseToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :default_license, :string, default: nil
  end
end
