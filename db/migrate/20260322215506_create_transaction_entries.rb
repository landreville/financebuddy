class CreateTransactionEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.integer :entry_type, null: false
      t.integer :status, null: false, default: 0
      t.string :payee
      t.string :category
      t.string :memo

      t.timestamps
    end

    add_index :transaction_entries, [:account_id, :date]
    add_index :transaction_entries, :status
  end
end
