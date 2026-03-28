class CreateTransactionLines < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_lines do |t|
      t.references :transaction_entry, null: false,
        foreign_key: { to_table: :transactions, on_delete: :cascade }
      t.references :account, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :memo
      t.timestamps
    end
  end
end
