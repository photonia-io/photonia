# frozen_string_literal: true

# Tag and album-membership writes never updated photos, so tsv drifted out
# of sync (#77). This rebuilds it for every row without touching updated_at.
class RefreshPhotosTsv < ActiveRecord::Migration[7.2]
  def up
    execute 'UPDATE photos SET title = title'
  end

  def down
    # tsv is derived; nothing to revert
  end
end
