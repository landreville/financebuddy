class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.references :category_group, null: false, foreign_key: { on_delete: :restrict }
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.references :account, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.boolean :system_managed, null: false, default: false
      t.references :credit_card_account, null: true, foreign_key: { to_table: :accounts }
      t.integer :display_order, null: false, default: 0
      t.boolean :archived, null: false, default: false
      t.timestamps
    end
    add_index :categories, [:ledger_id, :archived]
    add_index :categories, :account_id, unique: true
  end
end
