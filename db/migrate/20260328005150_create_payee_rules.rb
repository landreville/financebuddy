class CreatePayeeRules < ActiveRecord::Migration[8.0]
  def change
    create_table :payee_rules do |t|
      t.references :ledger, null: false, foreign_key: {on_delete: :cascade}
      t.references :payee, null: false, foreign_key: {on_delete: :cascade}
      t.references :category, null: false, foreign_key: {on_delete: :restrict}
      t.string :match_type, null: false, default: "exact"
      t.string :pattern, null: false
      t.timestamps
    end
  end
end
