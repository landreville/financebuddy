class CreateImportProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :import_profiles do |t|
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :file_format, null: false
      t.jsonb :column_mapping
      t.string :date_format
      t.string :amount_style
      t.integer :debit_column
      t.integer :credit_column
      t.integer :indicator_column
      t.integer :skip_rows, null: false, default: 0
      t.timestamps
    end
  end
end
