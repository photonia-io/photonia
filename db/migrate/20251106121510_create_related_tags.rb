# frozen_string_literal: true

class CreateRelatedTags < ActiveRecord::Migration[7.2]
  def change
    create_table :related_tags do |t|
      t.bigint :tag_id_from, null: false
      t.bigint :tag_id_to, null: false
      t.integer :support, null: false
      t.integer :support_from, null: false
      t.integer :support_to, null: false
      t.float :confidence, null: false
      t.float :lift, null: false
      t.float :jaccard, null: false
      t.timestamps null: false
    end

    add_index :related_tags, %i[tag_id_from tag_id_to], unique: true
    add_index :related_tags, :tag_id_to
    add_foreign_key :related_tags, :tags, column: :tag_id_from
    add_foreign_key :related_tags, :tags, column: :tag_id_to
  end
end
