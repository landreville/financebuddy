class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.date :date, null: false
      t.references :payee, null: true, foreign_key: { on_delete: :nullify }
      t.text :memo
      t.string :status, null: false, default: "uncleared"
      t.string :entry_type, null: false
      t.boolean :approved, null: false, default: true
      t.bigint :recurring_transaction_id
      t.string :bank_fitid
      t.date :bank_posted_date
      t.timestamps
    end
    add_index :transactions, [:ledger_id, :date]
    add_index :transactions, [:ledger_id, :payee_id]
    add_index :transactions, :recurring_transaction_id
    add_index :transactions, [:ledger_id, :bank_fitid]
  end
end
