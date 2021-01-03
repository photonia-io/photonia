class ConvertSerialNumberToBigint < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL
      ALTER TABLE photos ALTER COLUMN serial_number TYPE BIGINT USING (serial_number::bigint), ALTER COLUMN serial_number SET NOT NULL;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE photos ALTER COLUMN serial_number TYPE CHARACTER VARYING;
    SQL
  end
end
