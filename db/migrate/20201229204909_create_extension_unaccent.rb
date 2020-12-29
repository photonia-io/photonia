class CreateExtensionUnaccent < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL
      CREATE EXTENSION unaccent;
    SQL
  end

  def down
    execute <<~SQL
      DROP EXTENSION unaccent;
    SQL
  end
end
