# frozen_string_literal: true

class DropTagImpressions < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM impressions WHERE impressionable_type = 'ActsAsTaggableOn::Tag'"
    remove_column :tags, :impressions_count
  end

  def down
    add_column :tags, :impressions_count, :integer, default: 0, null: false
  end
end
