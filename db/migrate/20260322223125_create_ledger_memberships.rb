class CreateLedgerMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_memberships do |t|
      t.references :ledger, null: false, foreign_key: {on_delete: :cascade}
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "owner"

      t.timestamps
    end
    add_index :ledger_memberships, [:ledger_id, :user_id], unique: true
  end
end
