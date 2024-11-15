class CreateJoinTableUsersRoles < ActiveRecord::Migration[7.2]
  def change
    create_join_table :users, :roles do |t|
      t.index :user_id
      t.index :role_id
    end
  end
end
