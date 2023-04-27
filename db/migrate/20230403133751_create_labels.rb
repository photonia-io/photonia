# frozen_string_literal: true

class CreateLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :labels do |t|
      t.references :photo, null: false, foreign_key: true
      t.string :name
      t.float :confidence
      t.float :top
      t.float :left
      t.float :width
      t.float :height

      t.timestamps
    end
  end
end
