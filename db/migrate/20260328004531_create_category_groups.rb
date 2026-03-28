class CreateCategoryGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :category_groups do |t|
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.boolean :system_managed, null: false, default: false
      t.integer :display_order, null: false, default: 0
      t.boolean :archived, null: false, default: false
      t.timestamps
    end
    add_index :category_groups, [:ledger_id, :archived]
  end
end
