# frozen_string_literal: true

class AddImpressionsCountToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :impressions_count, :integer, null: false, default: 0
  end
end
