class CreatePayees < ActiveRecord::Migration[8.0]
  def change
    create_table :payees do |t|
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.timestamps
    end
    add_index :payees, [:ledger_id, :name], unique: true
  end
end
