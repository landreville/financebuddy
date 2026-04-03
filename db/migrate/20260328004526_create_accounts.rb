class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.references :ledger, null: false, foreign_key: {on_delete: :cascade}
      t.string :name, null: false
      t.string :account_type, null: false
      t.boolean :on_budget, null: false, default: true
      t.decimal :balance, precision: 12, scale: 2, null: false, default: 0
      t.decimal :cleared_balance, precision: 12, scale: 2, null: false, default: 0
      t.datetime :reconciled_at
      t.integer :display_order, null: false, default: 0
      t.boolean :archived, null: false, default: false
      t.timestamps
    end
    add_index :accounts, [:ledger_id, :account_type]
    add_index :accounts, [:ledger_id, :archived]
  end
end
