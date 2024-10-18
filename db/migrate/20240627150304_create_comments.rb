class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.string :serial_number
      t.references :commentable, polymorphic: true, null: false
      t.references :user, null: true, foreign_key: true
      t.references :flickr_user, null: true, foreign_key: true
      t.string :flickr_link, null: true
      t.text :body
      t.text :body_html

    t.timestamps
    end
  end
end
