class CreateBudgetAllocations < ActiveRecord::Migration[8.0]
  def change
    create_table :budget_allocations do |t|
      t.references :ledger, null: false, foreign_key: { on_delete: :cascade }
      t.references :category, null: false, foreign_key: { on_delete: :restrict }
      t.date :month, null: false
      t.decimal :assigned, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :budget_allocations, [:ledger_id, :month]
    add_index :budget_allocations, [:category_id, :month], unique: true
  end
end
