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

ActiveRecord::Schema[8.0].define(version: 2026_03_28_004904) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "accounts", force: :cascade do |t|
    t.bigint "ledger_id", null: false
    t.string "name", null: false
    t.string "account_type", null: false
    t.boolean "on_budget", default: true, null: false
    t.decimal "balance", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "cleared_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "reconciled_at"
    t.integer "display_order", default: 0, null: false
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ledger_id", "account_type"], name: "index_accounts_on_ledger_id_and_account_type"
    t.index ["ledger_id", "archived"], name: "index_accounts_on_ledger_id_and_archived"
    t.index ["ledger_id"], name: "index_accounts_on_ledger_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "category_group_id", null: false
    t.bigint "ledger_id", null: false
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.boolean "system_managed", default: false, null: false
    t.bigint "credit_card_account_id"
    t.integer "display_order", default: 0, null: false
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_categories_on_account_id", unique: true
    t.index ["category_group_id"], name: "index_categories_on_category_group_id"
    t.index ["credit_card_account_id"], name: "index_categories_on_credit_card_account_id"
    t.index ["ledger_id", "archived"], name: "index_categories_on_ledger_id_and_archived"
    t.index ["ledger_id"], name: "index_categories_on_ledger_id"
  end

  create_table "category_groups", force: :cascade do |t|
    t.bigint "ledger_id", null: false
    t.string "name", null: false
    t.boolean "system_managed", default: false, null: false
    t.integer "display_order", default: 0, null: false
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ledger_id", "archived"], name: "index_category_groups_on_ledger_id_and_archived"
    t.index ["ledger_id"], name: "index_category_groups_on_ledger_id"
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

  create_table "payees", force: :cascade do |t|
    t.bigint "ledger_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ledger_id", "name"], name: "index_payees_on_ledger_id_and_name", unique: true
    t.index ["ledger_id"], name: "index_payees_on_ledger_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transaction_lines", force: :cascade do |t|
    t.bigint "transaction_entry_id", null: false
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_transaction_lines_on_account_id"
    t.index ["transaction_entry_id"], name: "index_transaction_lines_on_transaction_entry_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "ledger_id", null: false
    t.date "date", null: false
    t.bigint "payee_id"
    t.text "memo"
    t.string "status", default: "uncleared", null: false
    t.string "entry_type", null: false
    t.boolean "approved", default: true, null: false
    t.bigint "recurring_transaction_id"
    t.string "bank_fitid"
    t.date "bank_posted_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ledger_id", "bank_fitid"], name: "index_transactions_on_ledger_id_and_bank_fitid"
    t.index ["ledger_id", "date"], name: "index_transactions_on_ledger_id_and_date"
    t.index ["ledger_id", "payee_id"], name: "index_transactions_on_ledger_id_and_payee_id"
    t.index ["ledger_id"], name: "index_transactions_on_ledger_id"
    t.index ["payee_id"], name: "index_transactions_on_payee_id"
    t.index ["recurring_transaction_id"], name: "index_transactions_on_recurring_transaction_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "accounts", "ledgers", on_delete: :cascade
  add_foreign_key "categories", "accounts"
  add_foreign_key "categories", "accounts", column: "credit_card_account_id"
  add_foreign_key "categories", "category_groups", on_delete: :restrict
  add_foreign_key "categories", "ledgers", on_delete: :cascade
  add_foreign_key "category_groups", "ledgers", on_delete: :cascade
  add_foreign_key "ledger_memberships", "ledgers", on_delete: :cascade
  add_foreign_key "ledger_memberships", "users"
  add_foreign_key "payees", "ledgers", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "transaction_lines", "accounts", on_delete: :restrict
  add_foreign_key "transaction_lines", "transactions", column: "transaction_entry_id", on_delete: :cascade
  add_foreign_key "transactions", "ledgers", on_delete: :cascade
  add_foreign_key "transactions", "payees", on_delete: :nullify
end
