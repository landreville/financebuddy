# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_22_215506) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "account_type", null: false
    t.integer "budget_status", null: false
    t.decimal "balance", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_type"], name: "index_accounts_on_account_type"
    t.index ["budget_status"], name: "index_accounts_on_budget_status"
  end

  create_table "transaction_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.date "date", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.integer "entry_type", null: false
    t.integer "status", default: 0, null: false
    t.string "payee"
    t.string "category"
    t.string "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "date"], name: "index_transaction_entries_on_account_id_and_date"
    t.index ["account_id"], name: "index_transaction_entries_on_account_id"
    t.index ["status"], name: "index_transaction_entries_on_status"
  end

  add_foreign_key "transaction_entries", "accounts"
end
