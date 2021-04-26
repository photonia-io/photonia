# frozen_string_literal: true

class CreateExtensionUnaccent < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL.squish
      CREATE EXTENSION unaccent;
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP EXTENSION unaccent;
    SQL
  end
end
