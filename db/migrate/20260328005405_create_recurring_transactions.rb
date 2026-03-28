class CreateRecurringTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :recurring_transactions do |t|
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.references :account, null: false, foreign_key: true
      t.references :transfer_account, null: true, foreign_key: { to_table: :accounts }
      t.references :payee, null: true, foreign_key: true
      t.references :category, null: true, foreign_key: true
      t.string :entry_type, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :memo
      t.string :frequency, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.date :next_due_date, null: false
      t.boolean :auto_enter, null: false, default: false
      t.timestamps
    end
    add_index :recurring_transactions, [:ledger_id, :next_due_date]
    add_index :recurring_transactions, [:ledger_id, :auto_enter, :next_due_date],
      name: "idx_recurring_auto_enter_due"

    add_foreign_key :transactions, :recurring_transactions, column: :recurring_transaction_id
  end
end
