class DeviseTokenAuthChangeUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :provider, null: false, default: 'email'
      t.string :uid, null: false, default: ''
      t.json :tokens
    end

    add_index :users, %i[id provider], unique: true
  end
end
