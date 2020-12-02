class CreateTaggingSources < ActiveRecord::Migration[6.0]
  def change
    create_table :tagging_sources do |t|
      t.string :name
      t.timestamps
    end
  end
end
