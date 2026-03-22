class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :account_type, null: false
      t.integer :budget_status, null: false
      t.decimal :balance, precision: 15, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :accounts, :budget_status
    add_index :accounts, :account_type
  end
end
