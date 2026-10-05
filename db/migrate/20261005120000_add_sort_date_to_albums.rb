# frozen_string_literal: true

# Optional date overriding created_at in album list ordering, so backfilled
# albums can sit where their content belongs. nil means "use created_at".
class AddSortDateToAlbums < ActiveRecord::Migration[8.0]
  def change
    add_column :albums, :sort_date, :date
  end
end
