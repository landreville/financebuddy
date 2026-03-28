class CreateImportEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :import_entries do |t|
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.references :account, null: false, foreign_key: true
      t.references :import_profile, null: true, foreign_key: true
      t.string :batch_id, null: false
      t.date :date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :payee_name
      t.string :memo
      t.string :fitid
      t.string :fingerprint
      t.references :category, null: true, foreign_key: true
      t.references :matched_transaction, null: true, foreign_key: { to_table: :transactions }
      t.string :match_confidence
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :import_entries, :batch_id
    add_index :import_entries, [:ledger_id, :fitid]
    add_index :import_entries, [:ledger_id, :fingerprint]
  end
end
