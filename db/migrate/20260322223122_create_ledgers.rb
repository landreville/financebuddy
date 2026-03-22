class CreateLedgers < ActiveRecord::Migration[8.0]
  def change
    create_table :ledgers do |t|
      t.string :name, null: false
      t.string :currency, limit: 3, null: false, default: "CAD"

      t.timestamps
    end
  end
end
