class AddSignupProviderToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :signup_provider, :string, null: false, default: 'local'
  end
end
