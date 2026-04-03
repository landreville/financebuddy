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

ActiveRecord::Schema[8.0].define(version: 2026_03_22_223125) do
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

  create_table "ledger_memberships", force: :cascade do |t|
    t.bigint "ledger_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "owner", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ledger_id", "user_id"], name: "index_ledger_memberships_on_ledger_id_and_user_id", unique: true
    t.index ["ledger_id"], name: "index_ledger_memberships_on_ledger_id"
    t.index ["user_id"], name: "index_ledger_memberships_on_user_id"
  end

  create_table "ledgers", force: :cascade do |t|
    t.string "name", null: false
    t.string "currency", limit: 3, default: "CAD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
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

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "ledger_memberships", "ledgers", on_delete: :cascade
  add_foreign_key "ledger_memberships", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "transaction_entries", "accounts"
end
