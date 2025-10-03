# frozen_string_literal: true

# migration to add sorting_type and sorting_order to albums
class AddSortingToAlbums < ActiveRecord::Migration[7.2]
  def change
    change_table :albums, bulk: true do |t|
      t.string :sorting_type, default: 'taken_at', null: false
      t.string :sorting_order, default: 'asc', null: false
    end
  end
end
