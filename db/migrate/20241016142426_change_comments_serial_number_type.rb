class ChangeCommentsSerialNumberType < ActiveRecord::Migration[7.1]
  def change
    change_column :comments, :serial_number, :bigint, using: 'serial_number::bigint'
  end
end
