# frozen_string_literal: true

# One level of replies: a reply's parent must itself be top-level (enforced
# in the model, not here). serial_number becomes unique so it's safe as the
# GraphQL id now that comments are user-created, not just Flickr-imported.
class AddParentIdToComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :parent, null: true, foreign_key: { to_table: :comments }, index: true
    add_index :comments, :serial_number, unique: true
  end
end
