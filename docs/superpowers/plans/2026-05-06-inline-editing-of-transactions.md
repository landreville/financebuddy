# Inline Editing of Transactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users click a transaction row on the account page, edit `date`, `payee`, `category`, `memo`, and amount in place, and save by clicking Save, pressing Enter, or moving focus outside the row.

**Architecture:** Turbo Frame per row swapped between read-only and editable partials. A `TransactionUpdater` service handles the double-entry mechanics (sign-flipped amounts, payee/category find-or-create, transfer→expense conversion when a category is set). Three small Stimulus controllers (`row-edit`, `row-edit-form`, `autocomplete`) handle click-to-edit, blur-to-save, and type-ahead with a "Create '…'" affordance. Reconciled rows are locked client-side and server-side. End-to-end coverage is in Playwright (newly wired up); units are in Minitest.

**Tech Stack:** Rails 8, PostgreSQL (pgvector), Hotwire (Turbo + Stimulus), importmap, Bootstrap 5.3 + custom SCSS, Minitest with fixtures, Playwright for end-to-end.

**Spec:** `docs/superpowers/specs/2026-05-06-inline-editing-of-transactions-design.md`

---

## File Inventory

### New

| Path | Responsibility |
| ---- | -------------- |
| `app/services/transaction_updater.rb` | Double-entry update logic in one DB transaction |
| `app/controllers/transactions_controller.rb` | `edit` and `update` returning HTML inside the row's Turbo Frame |
| `app/controllers/payees_controller.rb` | `index` JSON for payee autocomplete |
| `app/controllers/categories_controller.rb` | `index` JSON for category autocomplete |
| `app/controllers/test_sessions_controller.rb` | Test-only login (Playwright only) |
| `app/views/transactions/_row.html.erb` | Read-only `<tr>` |
| `app/views/transactions/_edit_row.html.erb` | Editable `<tr>` with form, inputs, Save/Cancel |
| `app/views/transactions/edit.html.erb` | Wraps `_edit_row` in matching `turbo_frame_tag` |
| `app/views/transactions/update.html.erb` | Wraps `_row` in matching `turbo_frame_tag` (success path) |
| `app/javascript/controllers/row_edit_controller.js` | Read-only row → click → fetch edit row into frame |
| `app/javascript/controllers/row_edit_form_controller.js` | Submit on row blur, Save/Cancel/Enter/Escape |
| `app/javascript/controllers/autocomplete_controller.js` | Type-ahead + "Create '…'" |
| `app/assets/stylesheets/components/_inline_edit.scss` | Row edit styling |
| `lib/tasks/playwright.rake` | `playwright:seed` task that wipes DB and inserts known data |
| `tests/support/auth.ts` | Helper that hits `/test/login` and stashes cookies |
| `tests/support/global-setup.ts` | Runs the seed task once per Playwright session |
| `tests/transactions/inline_edit.spec.ts` | Basic memo edit |
| `tests/transactions/inline_edit_payee.spec.ts` | Create new payee on the fly |
| `tests/transactions/inline_edit_category.spec.ts` | Convert transfer → expense via category |
| `tests/transactions/inline_edit_validation.spec.ts` | Bad input keeps row in edit mode |
| `tests/transactions/inline_edit_reconciled.spec.ts` | Reconciled row is locked |
| `tests/transactions/inline_edit_keyboard.spec.ts` | Tab / Enter / Escape behaviour |
| `test/services/transaction_updater_test.rb` | Service unit tests |

### Modified

| Path | Why |
| ---- | --- |
| `config/routes.rb` | New resources + test-only login route |
| `app/models/transaction_entry.rb` | Sum-to-zero validation + `compute_entry_type` helper |
| `app/views/accounts/show.html.erb` | Replace inline row markup with `turbo_frame_tag` + `_row` partial |
| `app/assets/stylesheets/application.bootstrap.scss` | `@import` the new component partial |
| `playwright.config.ts` | Uncomment `webServer`, set `baseURL`, register `globalSetup` |
| `test/models/transaction_entry_test.rb` | Cases for sum-to-zero validation |

### Deleted

| Path | Why |
| ---- | --- |
| `tests/example.spec.ts` | Demo spec; replaced by real specs |

---

## Task 1: Sum-to-zero validation on `TransactionEntry`

**Files:**
- Modify: `app/models/transaction_entry.rb`
- Test: `test/models/transaction_entry_test.rb`

- [ ] **Step 1: Write failing tests**

Append to `test/models/transaction_entry_test.rb`:

```ruby
test "balanced lines pass sum-to-zero validation" do
  entry = TransactionEntry.new(
    ledger: ledgers(:personal),
    date: Date.current,
    entry_type: "expense",
    status: "uncleared"
  )
  entry.transaction_lines.build(account: accounts(:chequing), amount: -10)
  entry.transaction_lines.build(account: accounts(:groceries_expense), amount: 10)
  assert entry.valid?, entry.errors.full_messages.to_sentence
end

test "unbalanced lines fail sum-to-zero validation" do
  entry = TransactionEntry.new(
    ledger: ledgers(:personal),
    date: Date.current,
    entry_type: "expense",
    status: "uncleared"
  )
  entry.transaction_lines.build(account: accounts(:chequing), amount: -10)
  entry.transaction_lines.build(account: accounts(:groceries_expense), amount: 5)
  assert_not entry.valid?
  assert_includes entry.errors[:base].join, "sum to zero"
end

test "empty lines collection passes sum-to-zero validation" do
  entry = TransactionEntry.new(
    ledger: ledgers(:personal),
    date: Date.current,
    entry_type: "expense",
    status: "uncleared"
  )
  assert entry.valid?, entry.errors.full_messages.to_sentence
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```
bin/rails test test/models/transaction_entry_test.rb -n /sum.to.zero/
```

Expected: 2 failures (balanced and unbalanced; the empty-lines case happens to pass already because the validation doesn't exist yet — that's fine, it'll keep passing after).

- [ ] **Step 3: Add the validation**

Edit `app/models/transaction_entry.rb`. Add the validate line before the closing `end`, and a private method:

```ruby
class TransactionEntry < ApplicationRecord
  self.table_name = "transactions"
  ENTRY_TYPES = %w[expense income transfer opening_balance].freeze
  STATUSES = %w[uncleared cleared reconciled].freeze
  belongs_to :ledger
  belongs_to :payee, optional: true
  belongs_to :recurring_transaction, optional: true
  has_many :transaction_lines, dependent: :destroy
  validates :date, presence: true
  validates :entry_type, presence: true, inclusion: {in: ENTRY_TYPES}
  validates :status, inclusion: {in: STATUSES}
  validate :lines_sum_to_zero

  private

  def lines_sum_to_zero
    amounts = transaction_lines.reject(&:marked_for_destruction?).map(&:amount).compact
    return if amounts.empty?
    total = amounts.sum
    errors.add(:base, "transaction lines must sum to zero (currently #{total})") unless total.zero?
  end
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```
bin/rails test test/models/transaction_entry_test.rb
```

Expected: all green.

- [ ] **Step 5: Commit**

```
git add app/models/transaction_entry.rb test/models/transaction_entry_test.rb
git commit -m "Add sum-to-zero validation to TransactionEntry"
```

---

## Task 2: `compute_entry_type` helper on `TransactionEntry`

**Files:**
- Modify: `app/models/transaction_entry.rb`
- Test: `test/models/transaction_entry_test.rb`

- [ ] **Step 1: Write failing tests**

Append to `test/models/transaction_entry_test.rb`:

```ruby
test "compute_entry_type returns transfer when both lines are user accounts" do
  entry = TransactionEntry.new(ledger: ledgers(:personal))
  entry.transaction_lines.build(account: accounts(:chequing), amount: -100)
  savings = ledgers(:personal).accounts.create!(name: "Savings", account_type: "cash")
  entry.transaction_lines.build(account: savings, amount: 100)
  assert_equal "transfer", entry.compute_entry_type
end

test "compute_entry_type returns expense when offsetting account is expense" do
  entry = TransactionEntry.new(ledger: ledgers(:personal))
  entry.transaction_lines.build(account: accounts(:chequing), amount: -10)
  entry.transaction_lines.build(account: accounts(:groceries_expense), amount: 10)
  assert_equal "expense", entry.compute_entry_type
end

test "compute_entry_type returns income when offsetting account is revenue" do
  revenue = ledgers(:personal).accounts.create!(name: "Salary", account_type: "revenue")
  entry = TransactionEntry.new(ledger: ledgers(:personal))
  entry.transaction_lines.build(account: accounts(:chequing), amount: 1000)
  entry.transaction_lines.build(account: revenue, amount: -1000)
  assert_equal "income", entry.compute_entry_type
end

test "compute_entry_type falls back to current entry_type when lines aren't a clean pair" do
  entry = TransactionEntry.new(ledger: ledgers(:personal), entry_type: "opening_balance")
  assert_equal "opening_balance", entry.compute_entry_type
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```
bin/rails test test/models/transaction_entry_test.rb -n /compute_entry_type/
```

Expected: NoMethodError or all four fail.

- [ ] **Step 3: Implement**

Add to `app/models/transaction_entry.rb` (before the `private` block):

```ruby
def compute_entry_type
  lines = transaction_lines.reject(&:marked_for_destruction?)
  return entry_type if lines.size != 2
  types = lines.map { |l| l.account.account_type }
  return "transfer" if types.all? { |t| Account::USER_ACCOUNT_TYPES.include?(t) }
  return "expense" if types.include?("expense")
  return "income" if types.include?("revenue")
  entry_type
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```
bin/rails test test/models/transaction_entry_test.rb
```

Expected: all green.

- [ ] **Step 5: Commit**

```
git add app/models/transaction_entry.rb test/models/transaction_entry_test.rb
git commit -m "Add compute_entry_type helper to TransactionEntry"
```

---

## Task 3: `TransactionUpdater` skeleton + reconciled rejection + scalars

**Files:**
- Create: `app/services/transaction_updater.rb`
- Test: `test/services/transaction_updater_test.rb`

- [ ] **Step 1: Write failing test**

Create `test/services/transaction_updater_test.rb`:

```ruby
require "test_helper"

class TransactionUpdaterTest < ActiveSupport::TestCase
  setup do
    @ledger = ledgers(:personal)
    @account = accounts(:chequing)
    @entry = transactions(:grocery_expense)
  end

  test "updates date and memo on an uncleared entry" do
    updater = TransactionUpdater.new(
      @entry,
      visible_account: @account,
      params: {date: Date.new(2026, 1, 15), memo: "new memo"}
    )
    assert updater.call
    @entry.reload
    assert_equal Date.new(2026, 1, 15), @entry.date
    assert_equal "new memo", @entry.memo
  end

  test "rejects edits to a reconciled entry" do
    @entry.update_column(:status, "reconciled")
    updater = TransactionUpdater.new(
      @entry,
      visible_account: @account,
      params: {memo: "should not save"}
    )
    assert_not updater.call
    assert_includes @entry.errors[:base].join, "Reconciled"
    @entry.reload
    assert_not_equal "should not save", @entry.memo
  end
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```
bin/rails test test/services/transaction_updater_test.rb
```

Expected: NameError (TransactionUpdater not defined).

- [ ] **Step 3: Create the service**

Create `app/services/transaction_updater.rb`:

```ruby
class TransactionUpdater
  def initialize(entry, visible_account:, params:)
    @entry = entry
    @visible_account = visible_account
    @params = params
  end

  def call
    if @entry.status == "reconciled"
      @entry.errors.add(:base, "Reconciled transactions cannot be edited")
      return false
    end

    success = false
    ActiveRecord::Base.transaction do
      update_scalars
      success = @entry.save
      raise ActiveRecord::Rollback unless success
    end
    success
  end

  private

  def update_scalars
    @entry.date = @params[:date] if @params.key?(:date)
    @entry.memo = @params[:memo] if @params.key?(:memo)
  end
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```
bin/rails test test/services/transaction_updater_test.rb
```

Expected: 2 passing.

- [ ] **Step 5: Commit**

```
git add app/services/transaction_updater.rb test/services/transaction_updater_test.rb
git commit -m "Add TransactionUpdater skeleton with reconciled rejection and scalar updates"
```

---

## Task 4: `TransactionUpdater` payee resolution

**Files:**
- Modify: `app/services/transaction_updater.rb`
- Modify: `test/services/transaction_updater_test.rb`

- [ ] **Step 1: Write failing tests**

Append to `test/services/transaction_updater_test.rb` (inside the class):

```ruby
test "sets payee to existing payee by name" do
  existing = @ledger.payees.create!(name: "Costco")
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {payee_name: "Costco"}
  )
  assert updater.call
  assert_equal existing.id, @entry.reload.payee_id
end

test "creates a new payee when name does not match an existing one" do
  assert_nil @ledger.payees.find_by(name: "Brand-New Store")
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {payee_name: "Brand-New Store"}
  )
  assert updater.call
  assert_equal "Brand-New Store", @entry.reload.payee.name
  assert @ledger.payees.exists?(name: "Brand-New Store")
end

test "blank payee_name clears the payee" do
  @entry.update!(payee: @ledger.payees.create!(name: "Some Payee"))
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {payee_name: ""}
  )
  assert updater.call
  assert_nil @entry.reload.payee_id
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```
bin/rails test test/services/transaction_updater_test.rb -n /payee/
```

Expected: 3 failures (payee not being touched).

- [ ] **Step 3: Implement payee resolution**

Edit `app/services/transaction_updater.rb`. Add `resolve_payee` after `update_scalars` in `call`, and define the private method:

```ruby
def call
  if @entry.status == "reconciled"
    @entry.errors.add(:base, "Reconciled transactions cannot be edited")
    return false
  end

  success = false
  ActiveRecord::Base.transaction do
    update_scalars
    resolve_payee
    success = @entry.save
    raise ActiveRecord::Rollback unless success
  end
  success
end

private

def update_scalars
  @entry.date = @params[:date] if @params.key?(:date)
  @entry.memo = @params[:memo] if @params.key?(:memo)
end

def resolve_payee
  return unless @params.key?(:payee_name)
  name = @params[:payee_name].to_s.strip
  if name.blank?
    @entry.payee = nil
  else
    @entry.payee = Payee.find_or_create_by(name: name, ledger: @entry.ledger)
  end
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```
bin/rails test test/services/transaction_updater_test.rb
```

Expected: 5 passing.

- [ ] **Step 5: Commit**

```
git add app/services/transaction_updater.rb test/services/transaction_updater_test.rb
git commit -m "TransactionUpdater: resolve payee with find-or-create"
```

---

## Task 5: `TransactionUpdater` amount handling (out / in)

**Files:**
- Modify: `app/services/transaction_updater.rb`
- Modify: `test/services/transaction_updater_test.rb`

- [ ] **Step 1: Write failing tests**

Append:

```ruby
test "out_amount sets visible line to negative and offsetting line to positive" do
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {out_amount: "12.50", in_amount: ""}
  )
  assert updater.call
  visible = @entry.reload.transaction_lines.find { |l| l.account_id == @account.id }
  offsetting = @entry.transaction_lines.find { |l| l.account_id != @account.id }
  assert_equal(-12.50, visible.amount.to_f)
  assert_equal(12.50, offsetting.amount.to_f)
end

test "in_amount sets visible line to positive and offsetting line to negative" do
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {out_amount: "", in_amount: "42"}
  )
  assert updater.call
  visible = @entry.reload.transaction_lines.find { |l| l.account_id == @account.id }
  offsetting = @entry.transaction_lines.find { |l| l.account_id != @account.id }
  assert_equal(42.0, visible.amount.to_f)
  assert_equal(-42.0, offsetting.amount.to_f)
end

test "in_amount wins when both out and in are present" do
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {out_amount: "5", in_amount: "9"}
  )
  assert updater.call
  visible = @entry.reload.transaction_lines.find { |l| l.account_id == @account.id }
  assert_equal(9.0, visible.amount.to_f)
end

test "amount changes preserve sum-to-zero" do
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {out_amount: "33"}
  )
  assert updater.call
  total = @entry.reload.transaction_lines.sum(&:amount)
  assert_equal 0, total
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```
bin/rails test test/services/transaction_updater_test.rb -n /amount/
```

Expected: 4 failures.

- [ ] **Step 3: Implement amount handling**

Edit `app/services/transaction_updater.rb`. Add `update_amounts` to the `call` flow and define the helpers:

```ruby
def call
  if @entry.status == "reconciled"
    @entry.errors.add(:base, "Reconciled transactions cannot be edited")
    return false
  end

  success = false
  ActiveRecord::Base.transaction do
    update_scalars
    resolve_payee
    update_amounts
    success = @entry.save
    raise ActiveRecord::Rollback unless success
  end
  success
end

private

# ... existing update_scalars and resolve_payee ...

def update_amounts
  return unless @params.key?(:out_amount) || @params.key?(:in_amount)
  out_val = parse_amount(@params[:out_amount])
  in_val = parse_amount(@params[:in_amount])
  amount =
    if in_val
      in_val.abs
    elsif out_val
      -out_val.abs
    end
  return if amount.nil?
  visible_line.amount = amount
  offsetting_line.amount = -amount
end

def parse_amount(val)
  return nil if val.nil? || val.to_s.strip.empty?
  BigDecimal(val.to_s)
rescue ArgumentError
  nil
end

def visible_line
  @visible_line ||= @entry.transaction_lines.find { |l| l.account_id == @visible_account.id }
end

def offsetting_line
  @offsetting_line ||= @entry.transaction_lines.find { |l| l.account_id != @visible_account.id }
end
```

- [ ] **Step 4: Run tests to confirm they pass**

```
bin/rails test test/services/transaction_updater_test.rb
```

Expected: 9 passing.

- [ ] **Step 5: Commit**

```
git add app/services/transaction_updater.rb test/services/transaction_updater_test.rb
git commit -m "TransactionUpdater: handle out/in amount inputs with sign flip on offsetting line"
```

---

## Task 6: `TransactionUpdater` category handling + transfer conversion + entry_type recompute

**Files:**
- Modify: `app/services/transaction_updater.rb`
- Modify: `test/services/transaction_updater_test.rb`

- [ ] **Step 1: Write failing tests**

Append:

```ruby
test "category change to existing category swaps offsetting line account" do
  rent_account = @ledger.accounts.create!(name: "Rent", account_type: "expense")
  rent_category = Category.create!(name: "Rent", account: rent_account)
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {category_name: "Rent"}
  )
  assert updater.call
  offsetting = @entry.reload.transaction_lines.find { |l| l.account_id != @account.id }
  assert_equal rent_account.id, offsetting.account_id
end

test "category change creates Account and Category when name is new" do
  refute @ledger.accounts.exists?(name: "Hobbies")
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {category_name: "Hobbies"}
  )
  assert updater.call
  account = @ledger.accounts.find_by(name: "Hobbies")
  assert_equal "expense", account.account_type
  assert Category.exists?(name: "Hobbies", account: account)
  offsetting = @entry.reload.transaction_lines.find { |l| l.account_id != @account.id }
  assert_equal account.id, offsetting.account_id
end

test "blank category_name leaves offsetting line untouched" do
  before = @entry.transaction_lines.find { |l| l.account_id != @account.id }.account_id
  updater = TransactionUpdater.new(
    @entry, visible_account: @account, params: {category_name: ""}
  )
  assert updater.call
  after = @entry.reload.transaction_lines.find { |l| l.account_id != @account.id }.account_id
  assert_equal before, after
end

test "setting category on a transfer converts entry_type to expense" do
  savings = @ledger.accounts.create!(name: "Savings", account_type: "cash")
  transfer = TransactionEntry.create!(
    ledger: @ledger, date: Date.current, entry_type: "transfer", status: "uncleared"
  )
  transfer.transaction_lines.create!(account: @account, amount: -50)
  transfer.transaction_lines.create!(account: savings, amount: 50)
  groceries_account = accounts(:groceries_expense)
  Category.find_or_create_by!(name: "Groceries", account: groceries_account)

  updater = TransactionUpdater.new(
    transfer, visible_account: @account, params: {category_name: "Groceries"}
  )
  assert updater.call
  assert_equal "expense", transfer.reload.entry_type
end
```

- [ ] **Step 2: Run tests to confirm they fail**

```
bin/rails test test/services/transaction_updater_test.rb -n /category/
```

Expected: 4 failures.

- [ ] **Step 3: Implement category handling and entry_type recompute**

Edit `app/services/transaction_updater.rb`:

```ruby
def call
  if @entry.status == "reconciled"
    @entry.errors.add(:base, "Reconciled transactions cannot be edited")
    return false
  end

  success = false
  ActiveRecord::Base.transaction do
    update_scalars
    resolve_payee
    resolve_category
    update_amounts
    recompute_entry_type
    success = @entry.save
    raise ActiveRecord::Rollback unless success
  end
  success
end

private

# ... existing helpers ...

def resolve_category
  return unless @params.key?(:category_name)
  name = @params[:category_name].to_s.strip
  return if name.blank?

  category = @entry.ledger.categories
    .joins(:account)
    .where("LOWER(categories.name) = ?", name.downcase)
    .first

  if category.nil?
    account = @entry.ledger.accounts.create!(name: name, account_type: "expense")
    category = Category.create!(name: name, account: account)
  end

  offsetting_line.account_id = category.account_id
end

def recompute_entry_type
  @entry.entry_type = @entry.compute_entry_type
end
```

Note: `offsetting_line` is memoized; if `update_amounts` runs before `resolve_category`, the line reference is the same record so updating `account_id` on it works. The order in `call` puts `resolve_category` *before* `update_amounts` so the recomputed offsetting account is in place when amounts are mirrored. (Either order works because both touch the same in-memory record, but this order reads more naturally.)

- [ ] **Step 4: Run tests to confirm they pass**

```
bin/rails test test/services/transaction_updater_test.rb
```

Expected: 13 passing.

- [ ] **Step 5: Commit**

```
git add app/services/transaction_updater.rb test/services/transaction_updater_test.rb
git commit -m "TransactionUpdater: resolve category with find-or-create and recompute entry_type"
```

---

## Task 7: Routes for transactions, payees, categories

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Add routes**

Edit `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", :as => :rails_health_check

  get "dashboard" => "dashboard#index", as: :dashboard
  get "budget" => "budget#index", as: :budget
  resources :accounts, only: [:index, :show]
  resources :transactions, only: [:edit, :update]
  resources :payees, only: [:index]
  resources :categories, only: [:index]
  get "reports" => "reports#index", as: :reports
  resources :recurring_transactions, only: [:index], path: "recurring"

  if Rails.env.test?
    get "test/login", to: "test_sessions#create"
  end

  root "home#index"
end
```

- [ ] **Step 2: Verify routes load**

```
bin/rails routes -g transactions
bin/rails routes -g payees
bin/rails routes -g categories
```

Expected: see `edit_transaction GET /transactions/:id/edit`, `transaction PATCH/PUT /transactions/:id`, `payees GET /payees(.:format)`, `categories GET /categories(.:format)`.

- [ ] **Step 3: Commit**

```
git add config/routes.rb
git commit -m "Add routes for transactions edit/update, payees, categories, test login"
```

---

## Task 8: `PayeesController#index` JSON for autocomplete

**Files:**
- Create: `app/controllers/payees_controller.rb`
- Test: `test/controllers/payees_controller_test.rb`

- [ ] **Step 1: Write failing test**

Create `test/controllers/payees_controller_test.rb`:

```ruby
require "test_helper"

class PayeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jason)
    @ledger = ledgers(:personal)
    @user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1").tap do |s|
      cookies.signed[:session_id] = s.id
    end
  end

  test "returns matching payees as JSON, scoped to current ledger, filtered by q" do
    @ledger.payees.create!(name: "Costco")
    @ledger.payees.create!(name: "Walmart")
    get payees_url(q: "cost"), as: :json
    assert_response :success
    body = JSON.parse(@response.body)
    names = body.map { |p| p["name"] }
    assert_includes names, "Costco"
    refute_includes names, "Walmart"
  end

  test "returns up to 10 payees by default" do
    15.times { |i| @ledger.payees.create!(name: "Payee #{i}") }
    get payees_url(q: "Payee"), as: :json
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal 10, body.size
  end
end
```

(If `users(:jason)` doesn't exist as a fixture, look at `test/fixtures/users.yml` and use whatever the first user fixture is named, plus its `ledgers(:personal)` membership.)

- [ ] **Step 2: Run test to confirm it fails**

```
bin/rails test test/controllers/payees_controller_test.rb
```

Expected: missing controller.

- [ ] **Step 3: Implement controller**

Create `app/controllers/payees_controller.rb`:

```ruby
class PayeesController < ApplicationController
  before_action :set_current_ledger

  def index
    q = params[:q].to_s.strip
    payees = current_ledger.payees
    payees = payees.where("LOWER(name) LIKE ?", "%#{q.downcase}%") if q.present?
    payees = payees.order(:name).limit(10)
    render json: payees.as_json(only: [:id, :name])
  end
end
```

(`set_current_ledger` and `current_ledger` are already provided by `ApplicationController` — see how `AccountsController` uses them. If they live in a concern, include the same way.)

- [ ] **Step 4: Run test to confirm it passes**

```
bin/rails test test/controllers/payees_controller_test.rb
```

Expected: 2 passing.

- [ ] **Step 5: Commit**

```
git add app/controllers/payees_controller.rb test/controllers/payees_controller_test.rb
git commit -m "Add PayeesController#index JSON for autocomplete"
```

---

## Task 9: `CategoriesController#index` JSON for autocomplete

**Files:**
- Create: `app/controllers/categories_controller.rb`
- Test: `test/controllers/categories_controller_test.rb`

- [ ] **Step 1: Write failing test**

Create `test/controllers/categories_controller_test.rb`:

```ruby
require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jason)
    @ledger = ledgers(:personal)
    @user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1").tap do |s|
      cookies.signed[:session_id] = s.id
    end
  end

  test "returns matching categories as JSON, filtered by q" do
    rent_account = @ledger.accounts.create!(name: "Rent", account_type: "expense")
    Category.create!(name: "Rent", account: rent_account)
    food_account = @ledger.accounts.create!(name: "Food", account_type: "expense")
    Category.create!(name: "Food", account: food_account)
    get categories_url(q: "ren"), as: :json
    assert_response :success
    body = JSON.parse(@response.body)
    names = body.map { |c| c["name"] }
    assert_includes names, "Rent"
    refute_includes names, "Food"
    assert_equal rent_account.id, body.find { |c| c["name"] == "Rent" }["account_id"]
  end
end
```

- [ ] **Step 2: Run test to confirm it fails**

```
bin/rails test test/controllers/categories_controller_test.rb
```

Expected: missing controller.

- [ ] **Step 3: Implement controller**

Create `app/controllers/categories_controller.rb`:

```ruby
class CategoriesController < ApplicationController
  before_action :set_current_ledger

  def index
    q = params[:q].to_s.strip
    categories = current_ledger.categories.includes(:account)
    categories = categories.where("LOWER(categories.name) LIKE ?", "%#{q.downcase}%") if q.present?
    categories = categories.order(:name).limit(10)
    render json: categories.map { |c| {id: c.id, name: c.name, account_id: c.account_id} }
  end
end
```

- [ ] **Step 4: Run test to confirm it passes**

```
bin/rails test test/controllers/categories_controller_test.rb
```

Expected: 1 passing.

- [ ] **Step 5: Commit**

```
git add app/controllers/categories_controller.rb test/controllers/categories_controller_test.rb
git commit -m "Add CategoriesController#index JSON for autocomplete"
```

---

## Task 10: `TransactionsController` with `edit` and `update`

**Files:**
- Create: `app/controllers/transactions_controller.rb`
- Create: `app/views/transactions/edit.html.erb`
- Create: `app/views/transactions/update.html.erb`
- Create: `app/views/transactions/_row.html.erb` (placeholder; full content comes in Task 12)
- Create: `app/views/transactions/_edit_row.html.erb` (placeholder; full content comes in Task 13)
- Test: `test/controllers/transactions_controller_test.rb`

(We create stubs of the partials so the controller test renders successfully. Tasks 12 and 13 fill in the real content.)

- [ ] **Step 1: Create stub partials**

`app/views/transactions/_row.html.erb`:

```erb
<tr id="<%= dom_id(txn) %>" data-stub="row">
  <td colspan="7"><%= txn.memo %></td>
</tr>
```

`app/views/transactions/_edit_row.html.erb`:

```erb
<tr id="<%= dom_id(txn) %>" data-stub="edit_row">
  <td colspan="7">edit form for <%= txn.id %></td>
</tr>
```

`app/views/transactions/edit.html.erb`:

```erb
<%= turbo_frame_tag dom_id(@transaction) do %>
  <%= render "edit_row", txn: @transaction, account: @visible_account,
             categories_by_account: @categories_by_account,
             submitted_params: {} %>
<% end %>
```

`app/views/transactions/update.html.erb`:

```erb
<% if @transaction.errors.any? %>
  <%= turbo_frame_tag dom_id(@transaction) do %>
    <%= render "edit_row", txn: @transaction, account: @visible_account,
               categories_by_account: @categories_by_account,
               submitted_params: @submitted_params || {} %>
  <% end %>
<% else %>
  <%= turbo_frame_tag dom_id(@transaction) do %>
    <%= render "row", txn: @transaction, account: @visible_account,
               categories_by_account: @categories_by_account %>
  <% end %>
<% end %>
```

- [ ] **Step 2: Write failing controller test**

Create `test/controllers/transactions_controller_test.rb`:

```ruby
require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jason)
    @ledger = ledgers(:personal)
    @account = accounts(:chequing)
    @entry = transactions(:grocery_expense)
    @user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1").tap do |s|
      cookies.signed[:session_id] = s.id
    end
  end

  test "edit renders edit_row inside matching turbo frame" do
    get edit_transaction_url(@entry, account_id: @account.id)
    assert_response :success
    assert_match %r{<turbo-frame id="#{Regexp.escape(ActionView::RecordIdentifier.dom_id(@entry))}"}, @response.body
    assert_match %r{data-stub="edit_row"}, @response.body
  end

  test "edit returns 403 with read-only row for reconciled entries" do
    @entry.update_column(:status, "reconciled")
    get edit_transaction_url(@entry, account_id: @account.id)
    assert_response :forbidden
    assert_match %r{data-stub="row"}, @response.body
  end

  test "update success replaces with read-only row" do
    patch transaction_url(@entry, account_id: @account.id), params: {
      transaction: {memo: "via controller"}
    }
    assert_response :success
    assert_match %r{data-stub="row"}, @response.body
    assert_equal "via controller", @entry.reload.memo
  end

  test "update failure re-renders edit_row with status 422" do
    patch transaction_url(@entry, account_id: @account.id), params: {
      transaction: {date: ""}
    }
    assert_response :unprocessable_entity
    assert_match %r{data-stub="edit_row"}, @response.body
  end
end
```

- [ ] **Step 3: Run test to confirm it fails**

```
bin/rails test test/controllers/transactions_controller_test.rb
```

Expected: missing controller.

- [ ] **Step 4: Implement controller**

Create `app/controllers/transactions_controller.rb`:

```ruby
class TransactionsController < ApplicationController
  before_action :set_current_ledger
  before_action :set_transaction
  before_action :set_visible_account
  before_action :set_categories_by_account

  def edit
    if locked?
      render :edit, status: :forbidden, locals: {locked: true}
      return render_locked_row
    end
    @submitted_params = {}
    render :edit
  end

  def update
    @submitted_params = transaction_params.to_h.symbolize_keys
    updater = TransactionUpdater.new(
      @transaction,
      visible_account: @visible_account,
      params: @submitted_params
    )
    if updater.call
      render :update
    else
      render :update, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = current_ledger.transaction_entries
      .includes(:transaction_lines, :payee)
      .find(params[:id])
  end

  def set_visible_account
    @visible_account = current_ledger.accounts.find(params[:account_id])
  end

  def set_categories_by_account
    @categories_by_account = current_ledger.categories.index_by(&:account_id)
  end

  def locked?
    @transaction.status == "reconciled" || @transaction.transaction_lines.size != 2
  end

  def render_locked_row
    render template: "transactions/edit",
           status: :forbidden,
           locals: {render_row_instead: true}
  end

  def transaction_params
    params.require(:transaction).permit(
      :date, :memo, :payee_name, :category_name, :out_amount, :in_amount
    )
  end
end
```

The `edit.html.erb` template needs to render `_row` instead of `_edit_row` when the locked path is taken. Update `app/views/transactions/edit.html.erb`:

```erb
<%= turbo_frame_tag dom_id(@transaction) do %>
  <% if local_assigns[:render_row_instead] %>
    <%= render "row", txn: @transaction, account: @visible_account,
               categories_by_account: @categories_by_account %>
  <% else %>
    <%= render "edit_row", txn: @transaction, account: @visible_account,
               categories_by_account: @categories_by_account,
               submitted_params: @submitted_params || {} %>
  <% end %>
<% end %>
```

And simplify the controller's `edit` action — drop the duplicated `render`:

```ruby
def edit
  if locked?
    render :edit, status: :forbidden, locals: {render_row_instead: true}
  else
    @submitted_params = {}
    render :edit
  end
end
```

- [ ] **Step 5: Run test to confirm it passes**

```
bin/rails test test/controllers/transactions_controller_test.rb
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```
git add app/controllers/transactions_controller.rb app/views/transactions/ test/controllers/transactions_controller_test.rb
git commit -m "Add TransactionsController#edit and #update with Turbo Frame partials"
```

---

## Task 11: Test-only login endpoint

**Files:**
- Create: `app/controllers/test_sessions_controller.rb`
- Test: `test/controllers/test_sessions_controller_test.rb`

- [ ] **Step 1: Write failing test**

Create `test/controllers/test_sessions_controller_test.rb`:

```ruby
require "test_helper"

class TestSessionsControllerTest < ActionDispatch::IntegrationTest
  test "logs the user in and sets the session cookie" do
    user = users(:jason)
    get "/test/login", params: {user_id: user.id}
    assert_response :success
    # subsequent requests should be authenticated
    get accounts_url
    assert_response :success
  end
end
```

- [ ] **Step 2: Run test to confirm it fails**

```
bin/rails test test/controllers/test_sessions_controller_test.rb
```

Expected: routing or controller error.

- [ ] **Step 3: Implement**

Create `app/controllers/test_sessions_controller.rb`:

```ruby
class TestSessionsController < ApplicationController
  allow_unauthenticated_access only: :create

  def create
    return head :forbidden unless Rails.env.test?
    user = User.find(params[:user_id])
    session = user.sessions.create!(user_agent: "playwright", ip_address: request.remote_ip)
    cookies.signed.permanent[:session_id] = {value: session.id, httponly: true, same_site: :lax}
    head :ok
  end
end
```

- [ ] **Step 4: Run test to confirm it passes**

```
bin/rails test test/controllers/test_sessions_controller_test.rb
```

Expected: 1 passing.

- [ ] **Step 5: Commit**

```
git add app/controllers/test_sessions_controller.rb test/controllers/test_sessions_controller_test.rb
git commit -m "Add test-only /test/login endpoint for Playwright"
```

---

## Task 12: Real `_row.html.erb` partial + use it from `accounts/show.html.erb`

**Files:**
- Modify: `app/views/transactions/_row.html.erb`
- Modify: `app/views/accounts/show.html.erb`

- [ ] **Step 1: Replace the stub partial with the real read-only row**

Replace the contents of `app/views/transactions/_row.html.erb` (referencing the existing markup at `app/views/accounts/show.html.erb:59-80`):

```erb
<% line = txn.transaction_lines.find { |l| l.account_id == account.id } %>
<% other_line = txn.transaction_lines.find { |l| l.account_id != account.id } %>
<% locked = txn.status == "reconciled" %>
<% multi_line = txn.transaction_lines.size != 2 %>
<tr data-controller="row-edit"
    data-row-edit-url-value="<%= edit_transaction_path(txn, account_id: account.id) %>"
    <% if locked %>data-locked<% end %>
    <% if multi_line %>data-multi-line<% end %>
    data-txn-id="<%= txn.id %>">
  <td class="col-status">
    <span class="status-pill status-<%= txn.status %>"><%= txn.status[0].upcase %></span>
    <% if locked %><span class="lock-glyph" title="Reconciled — locked">🔒</span><% end %>
  </td>
  <td class="col-date"><%= txn.date.strftime("%y-%m-%d") %></td>
  <td class="col-payee"><%= txn.payee&.name || txn.entry_type.titleize %></td>
  <td class="col-cat"><%= categories_by_account[other_line&.account_id]&.name || "—" %></td>
  <td class="col-memo"><%= txn.memo %></td>
  <% if line && line.amount < 0 %>
    <td class="col-out has"><%= fmt_money(line.amount.abs) %></td>
    <td class="col-in"></td>
  <% elsif line %>
    <td class="col-out"></td>
    <td class="col-in has"><%= fmt_money(line.amount) %></td>
  <% else %>
    <td class="col-out"></td>
    <td class="col-in"></td>
  <% end %>
</tr>
```

(The pre-existing markup didn't have the status pill class scheme — match whatever's currently in `accounts/show.html.erb`. This is illustrative; copy the actual existing pill markup verbatim.)

- [ ] **Step 2: Update `accounts/show.html.erb` to use the partial**

Replace the row loop in `app/views/accounts/show.html.erb` (lines 59-80) with:

```erb
<% @transactions.each do |txn| %>
  <%= turbo_frame_tag dom_id(txn) do %>
    <%= render "transactions/row",
               txn:, account: @account,
               categories_by_account: @categories_by_account %>
  <% end %>
<% end %>
```

- [ ] **Step 3: Verify the page still renders unchanged**

```
bin/dev
```

Open `http://localhost:3000/accounts/<id>` in a browser. The transactions table should look identical to before. Confirm visually.

If a system test exists for `accounts/show`, run it:

```
bin/rails test test/system/
```

(There are none yet, but this catches any regression once they exist.)

- [ ] **Step 4: Commit**

```
git add app/views/transactions/_row.html.erb app/views/accounts/show.html.erb
git commit -m "Extract transactions row to partial and wrap in Turbo Frame"
```

---

## Task 13: Real `_edit_row.html.erb` partial

**Files:**
- Modify: `app/views/transactions/_edit_row.html.erb`

- [ ] **Step 1: Replace the stub with the real edit form**

```erb
<% line = txn.transaction_lines.find { |l| l.account_id == account.id } %>
<% other_line = txn.transaction_lines.find { |l| l.account_id != account.id } %>
<% current_payee = submitted_params[:payee_name] || txn.payee&.name %>
<% current_category = submitted_params[:category_name] || categories_by_account[other_line&.account_id]&.name %>
<% current_date = submitted_params[:date].presence || txn.date %>
<% current_memo = submitted_params[:memo] || txn.memo %>
<% out_val = submitted_params[:out_amount] || (line && line.amount < 0 ? line.amount.abs : nil) %>
<% in_val  = submitted_params[:in_amount]  || (line && line.amount >= 0 ? line.amount : nil) %>
<%= form_with model: txn,
              url: transaction_path(txn, account_id: account.id),
              method: :patch,
              data: {controller: "row-edit-form"},
              html: {class: "row-edit-form"} do |f| %>
  <tr class="is-editing" data-row-edit-form-target="row">
    <td class="col-status">
      <span class="status-pill status-<%= txn.status %>"><%= txn.status[0].upcase %></span>
    </td>
    <td class="col-date">
      <%= f.date_field :date, value: current_date,
            data: {row_edit_form_target: "input"} %>
      <div class="field-error" data-row-edit-form-target="errorDate">
        <%= txn.errors[:date].first %>
      </div>
    </td>
    <td class="col-payee" data-controller="autocomplete"
        data-autocomplete-url-value="<%= payees_path(format: :json) %>"
        data-autocomplete-allow-create-value="true">
      <%= f.text_field :payee_name, value: current_payee,
            autocomplete: "off",
            data: {row_edit_form_target: "input", autocomplete_target: "input"} %>
      <ul class="autocomplete-popover" data-autocomplete-target="list" hidden></ul>
      <div class="field-error" data-row-edit-form-target="errorPayeeName">
        <%= txn.errors[:payee_name].first %>
      </div>
    </td>
    <td class="col-cat" data-controller="autocomplete"
        data-autocomplete-url-value="<%= categories_path(format: :json) %>"
        data-autocomplete-allow-create-value="true">
      <%= f.text_field :category_name, value: current_category,
            autocomplete: "off",
            data: {row_edit_form_target: "input", autocomplete_target: "input"} %>
      <ul class="autocomplete-popover" data-autocomplete-target="list" hidden></ul>
      <div class="field-error" data-row-edit-form-target="errorCategoryName">
        <%= txn.errors[:category_name].first %>
      </div>
    </td>
    <td class="col-memo">
      <%= f.text_field :memo, value: current_memo,
            data: {row_edit_form_target: "input"} %>
      <div class="field-error" data-row-edit-form-target="errorMemo">
        <%= txn.errors[:memo].first %>
      </div>
    </td>
    <td class="col-out">
      <%= f.number_field :out_amount, value: out_val, step: "0.01",
            data: {row_edit_form_target: "input", action: "input->row-edit-form#blankIn"} %>
    </td>
    <td class="col-in">
      <%= f.number_field :in_amount, value: in_val, step: "0.01",
            data: {row_edit_form_target: "input", action: "input->row-edit-form#blankOut"} %>
      <div class="field-error" data-row-edit-form-target="errorAmount">
        <%= txn.errors[:base].first %>
      </div>
    </td>
  </tr>
<% end %>
<div class="row-edit-actions" data-row-edit-form-target="actions">
  <button type="button" class="btn btn--primary" data-action="row-edit-form#save">Save</button>
  <button type="button" class="btn btn--ghost" data-action="row-edit-form#cancel">Cancel</button>
</div>
```

(The actions div sits outside the `<tr>` because nesting non-cell elements inside a `<tr>` is invalid HTML. The Stimulus form controller manages it.)

A subtle point about `form_with` wrapping a `<tr>`: Rails' `form_with` emits `<form>...</form>`, which is not valid as a child of `<tbody>`. To work around this, the form tag itself should sit *outside* the `<tr>` and the inputs inside should be associated with the form via the `form` HTML attribute. Browsers are lenient enough that the simpler version above works in practice (Turbo's frame replacement keeps the form contained within the frame). If validation issues arise during Playwright testing, switch to using the `form` attribute on each input.

- [ ] **Step 2: Manual smoke test**

```
bin/dev
```

Visit an account page, click a row. With no Stimulus controllers yet, nothing happens — that's expected. The next tasks wire the JS.

To verify the partial renders cleanly, hit the edit endpoint directly:

```
curl -b "session_id=..." "http://localhost:3000/transactions/1/edit?account_id=1"
```

Expected: HTML containing the form fields.

- [ ] **Step 3: Commit**

```
git add app/views/transactions/_edit_row.html.erb
git commit -m "Add edit_row partial with form, autocomplete wrappers, save/cancel"
```

---

## Task 14: `row_edit_controller.js` (click read-only row → load edit row)

**Files:**
- Create: `app/javascript/controllers/row_edit_controller.js`

- [ ] **Step 1: Write the controller**

`app/javascript/controllers/row_edit_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("click", this.enterEdit.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("click", this.enterEdit.bind(this))
  }

  enterEdit(event) {
    if (this.element.hasAttribute("data-locked")) return
    if (this.element.hasAttribute("data-multi-line")) return
    const frame = this.element.closest("turbo-frame")
    if (!frame) return
    frame.src = this.urlValue
  }
}
```

- [ ] **Step 2: Manual smoke test**

```
bin/dev
```

Visit an account page. Click a (non-reconciled) transaction row. The row should swap to the edit form.

- [ ] **Step 3: Commit**

```
git add app/javascript/controllers/row_edit_controller.js
git commit -m "Add row_edit Stimulus controller"
```

---

## Task 15: `row_edit_form_controller.js` (submit on blur, Save/Cancel/Enter/Escape)

**Files:**
- Create: `app/javascript/controllers/row_edit_form_controller.js`

- [ ] **Step 1: Write the controller**

`app/javascript/controllers/row_edit_form_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Attached to the <form> wrapping an editable row.
// Submits on focus leaving the row entirely (tab between inner fields stays).
// Save/Cancel buttons call save/cancel actions explicitly.
// Enter submits, Escape cancels.
// blankIn / blankOut keep only one of the two amount inputs populated.
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.submitting = false
    this.boundFocusOut = this.maybeSave.bind(this)
    this.boundKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener("focusout", this.boundFocusOut)
    this.element.addEventListener("keydown", this.boundKeydown)
    // Focus the first input so blur semantics work immediately.
    queueMicrotask(() => this.inputTarget?.focus())
  }

  disconnect() {
    this.element.removeEventListener("focusout", this.boundFocusOut)
    this.element.removeEventListener("keydown", this.boundKeydown)
  }

  maybeSave(event) {
    if (this.submitting) return
    const next = event.relatedTarget
    if (next && this.element.contains(next)) return
    // Also stay if focus moves to the floating action buttons (sibling div).
    const actions = document.querySelector("[data-row-edit-form-target='actions']")
    if (next && actions && actions.contains(next)) return
    this.submit()
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.submit()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancel()
    }
  }

  save(event) {
    event?.preventDefault()
    this.submit()
  }

  submit() {
    if (this.submitting) return
    this.submitting = true
    this.element.requestSubmit()
  }

  cancel(event) {
    event?.preventDefault()
    const frame = this.element.closest("turbo-frame")
    if (!frame) return
    // Refetch the read-only row by reloading the parent show; or fetch /accounts/:id and pluck the frame.
    // Simpler: clear the frame's src to force a full reload of the matching frame from the server show.
    // Even simpler: navigate the frame to the account show, which re-renders all rows including this one.
    const accountId = this.element.action.match(/account_id=(\d+)/)?.[1]
    if (accountId) {
      frame.src = `/accounts/${accountId}`
    }
  }

  blankIn() {
    const inField = this.inputTargets.find(i => i.name === "transaction[in_amount]")
    if (inField) inField.value = ""
  }

  blankOut() {
    const outField = this.inputTargets.find(i => i.name === "transaction[out_amount]")
    if (outField) outField.value = ""
  }
}
```

A note on `cancel`: navigating the frame to the parent show is a heavy way to refresh one row. A lighter approach is to expose a small JSON or HTML endpoint that re-renders just the read-only row. Defer that optimization unless Playwright shows a noticeable jank.

- [ ] **Step 2: Manual smoke test**

```
bin/dev
```

Visit an account page; click a row; type in the memo; click outside the row. Network tab should show a PATCH `/transactions/:id`. The row should return to read-only with the new memo.

Click Cancel on a row in edit mode — it should snap back to read-only without saving.

- [ ] **Step 3: Commit**

```
git add app/javascript/controllers/row_edit_form_controller.js
git commit -m "Add row_edit_form Stimulus controller with submit-on-blur and Save/Cancel/Enter/Escape"
```

---

## Task 16: `autocomplete_controller.js` (type-ahead with Create option)

**Files:**
- Create: `app/javascript/controllers/autocomplete_controller.js`

- [ ] **Step 1: Write the controller**

`app/javascript/controllers/autocomplete_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    param: { type: String, default: "q" },
    allowCreate: Boolean
  }
  static targets = ["input", "list"]

  connect() {
    this.debounceTimer = null
    this.highlightedIndex = -1
    this.inputTarget.addEventListener("input", this.onInput.bind(this))
    this.inputTarget.addEventListener("keydown", this.onKeydown.bind(this))
    this.inputTarget.addEventListener("focus", this.onInput.bind(this))
    this.inputTarget.addEventListener("blur", this.onBlur.bind(this))
    this.listTarget.addEventListener("mousedown", this.onListMousedown.bind(this))
  }

  onInput() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.fetchSuggestions(), 150)
  }

  async fetchSuggestions() {
    const q = this.inputTarget.value
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set(this.paramValue, q)
    const response = await fetch(url, {headers: {Accept: "application/json"}})
    if (!response.ok) return
    const items = await response.json()
    this.renderItems(items, q)
  }

  renderItems(items, query) {
    this.listTarget.innerHTML = ""
    items.forEach((item, i) => {
      const li = document.createElement("li")
      li.textContent = item.name
      li.dataset.value = item.name
      li.dataset.index = i
      this.listTarget.appendChild(li)
    })
    if (this.allowCreateValue && query.trim() && !items.some(i => i.name.toLowerCase() === query.trim().toLowerCase())) {
      const li = document.createElement("li")
      li.textContent = `Create "${query.trim()}"`
      li.dataset.value = query.trim()
      li.dataset.index = items.length
      li.classList.add("is-create")
      this.listTarget.appendChild(li)
    }
    this.highlightedIndex = this.listTarget.children.length > 0 ? 0 : -1
    this.updateHighlight()
    this.listTarget.hidden = this.listTarget.children.length === 0
  }

  onKeydown(event) {
    if (this.listTarget.hidden) return
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.highlightedIndex = Math.min(this.highlightedIndex + 1, this.listTarget.children.length - 1)
      this.updateHighlight()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.highlightedIndex = Math.max(this.highlightedIndex - 1, 0)
      this.updateHighlight()
    } else if (event.key === "Enter" && this.highlightedIndex >= 0) {
      event.preventDefault()
      event.stopPropagation()
      this.selectByIndex(this.highlightedIndex)
    } else if (event.key === "Escape") {
      this.listTarget.hidden = true
    }
  }

  updateHighlight() {
    Array.from(this.listTarget.children).forEach((li, i) => {
      li.classList.toggle("is-highlighted", i === this.highlightedIndex)
    })
  }

  onListMousedown(event) {
    const li = event.target.closest("li")
    if (!li) return
    event.preventDefault() // prevent input blur before we read the value
    this.selectByIndex(parseInt(li.dataset.index, 10))
  }

  selectByIndex(i) {
    const li = this.listTarget.children[i]
    if (!li) return
    this.inputTarget.value = li.dataset.value
    this.listTarget.hidden = true
  }

  onBlur(event) {
    // Delay to allow the mousedown selection to fire first.
    setTimeout(() => { this.listTarget.hidden = true }, 100)
  }
}
```

- [ ] **Step 2: Manual smoke test**

```
bin/dev
```

Click a row, focus the payee input, type a few characters. Suggestions appear; arrows highlight; Enter selects; clicking a suggestion selects. Type a name no payee matches; "Create '…'" appears at the bottom; selecting it puts the typed text in the input.

- [ ] **Step 3: Commit**

```
git add app/javascript/controllers/autocomplete_controller.js
git commit -m "Add autocomplete Stimulus controller with Create option"
```

---

## Task 17: Inline edit styling

**Files:**
- Create: `app/assets/stylesheets/components/_inline_edit.scss`
- Modify: `app/assets/stylesheets/application.bootstrap.scss`

- [ ] **Step 1: Create the stylesheet**

`app/assets/stylesheets/components/_inline_edit.scss`:

```scss
.ledger {
  tr.is-editing {
    background: var(--paper-2);
    box-shadow: var(--shadow-bevel-in);
  }

  tr.is-editing td {
    overflow: visible; // so autocomplete popovers are not clipped
    position: relative;
  }

  tr.is-editing input,
  tr.is-editing select {
    width: 100%;
    height: calc(var(--row-h) - 8px);
    border: 0;
    background: transparent;
    font: inherit;
    color: inherit;
    padding: 0 4px;
    outline: 1px solid transparent;
  }

  tr.is-editing input:focus {
    outline: 1px solid var(--blue);
  }

  .field-error {
    position: absolute;
    left: 4px;
    top: calc(var(--row-h) - 4px);
    font-size: var(--fz-xs);
    color: var(--red);
    pointer-events: none;
    white-space: nowrap;
  }

  .field-error:empty {
    display: none;
  }

  .row-edit-actions {
    position: absolute;
    right: 0;
    top: 0;
    height: var(--row-h);
    display: flex;
    gap: 4px;
    padding: 4px;
    background: var(--paper-2);
    box-shadow: var(--shadow-bevel-out);
    z-index: 5;
  }

  .autocomplete-popover {
    position: absolute;
    top: 100%;
    left: 0;
    min-width: 100%;
    max-height: 200px;
    overflow-y: auto;
    margin: 0;
    padding: 0;
    list-style: none;
    background: var(--white);
    border: 1px solid var(--ink);
    z-index: 10;
  }

  .autocomplete-popover li {
    padding: 4px 8px;
    cursor: pointer;
  }

  .autocomplete-popover li.is-highlighted,
  .autocomplete-popover li:hover {
    background: var(--blue);
    color: var(--white);
  }

  .autocomplete-popover li.is-create {
    font-style: italic;
    border-top: 1px solid var(--muted);
  }

  tr[data-locked] {
    cursor: not-allowed;
  }

  .lock-glyph {
    font-size: var(--fz-xs);
    margin-left: 4px;
  }
}
```

- [ ] **Step 2: Import from the entry point**

Add to `app/assets/stylesheets/application.bootstrap.scss` (alongside the other `@import "components/..."` lines):

```scss
@import "components/inline_edit";
```

- [ ] **Step 3: Build CSS and verify**

```
yarn build:css
bin/dev
```

Visit an account page; click a row. Inputs should be sized to fit cells; the row should have a paper-2 background and inset shadow.

- [ ] **Step 4: Commit**

```
git add app/assets/stylesheets/components/_inline_edit.scss app/assets/stylesheets/application.bootstrap.scss
git commit -m "Add inline edit row styling"
```

---

## Task 18: Playwright config + seed task + auth helper

**Files:**
- Create: `lib/tasks/playwright.rake`
- Create: `tests/support/auth.ts`
- Create: `tests/support/global-setup.ts`
- Modify: `playwright.config.ts`
- Delete: `tests/example.spec.ts`

- [ ] **Step 1: Create the seed Rake task**

`lib/tasks/playwright.rake`:

```ruby
namespace :playwright do
  desc "Wipe the test DB and insert a known data set for Playwright specs"
  task seed: :environment do
    raise "playwright:seed is for the test environment only" unless Rails.env.test?

    ActiveRecord::Base.transaction do
      [TransactionLine, TransactionEntry, BudgetAllocation, PayeeRule, Payee,
       Category, Account, LedgerMembership, Ledger, Session, User].each(&:delete_all)

      user = User.create!(email_address: "playwright@example.com", password: "test1234")
      ledger = Ledger.create!(name: "Personal")
      LedgerMembership.create!(user: user, ledger: ledger, role: "owner")

      chequing = ledger.accounts.create!(name: "Chequing", account_type: "cash")
      savings  = ledger.accounts.create!(name: "Savings", account_type: "cash")
      groceries_acct = ledger.accounts.create!(name: "Groceries", account_type: "expense")
      Category.create!(name: "Groceries", account: groceries_acct)
      rent_acct = ledger.accounts.create!(name: "Rent", account_type: "expense")
      Category.create!(name: "Rent", account: rent_acct)
      salary_acct = ledger.accounts.create!(name: "Salary", account_type: "revenue")
      Category.create!(name: "Salary", account: salary_acct)

      costco = ledger.payees.create!(name: "Costco")

      # Expense (uncleared)
      e1 = TransactionEntry.create!(ledger: ledger, date: 7.days.ago, entry_type: "expense",
                                    status: "uncleared", memo: "Weekly groceries", payee: costco)
      e1.transaction_lines.create!(account: chequing,        amount: -42.50)
      e1.transaction_lines.create!(account: groceries_acct,  amount:  42.50)

      # Income (cleared)
      e2 = TransactionEntry.create!(ledger: ledger, date: 14.days.ago, entry_type: "income",
                                    status: "cleared", memo: "Paycheque")
      e2.transaction_lines.create!(account: chequing,    amount:  2500)
      e2.transaction_lines.create!(account: salary_acct, amount: -2500)

      # Transfer (uncleared)
      e3 = TransactionEntry.create!(ledger: ledger, date: 3.days.ago, entry_type: "transfer",
                                    status: "uncleared", memo: "To savings")
      e3.transaction_lines.create!(account: chequing, amount: -200)
      e3.transaction_lines.create!(account: savings,  amount:  200)

      # Reconciled expense
      e4 = TransactionEntry.create!(ledger: ledger, date: 30.days.ago, entry_type: "expense",
                                    status: "reconciled", memo: "Locked rent", payee: costco)
      e4.transaction_lines.create!(account: chequing,  amount: -1500)
      e4.transaction_lines.create!(account: rent_acct, amount:  1500)

      puts "Seeded user_id=#{user.id} ledger_id=#{ledger.id} chequing_id=#{chequing.id}"
      puts "PLAYWRIGHT_SEED user_id=#{user.id} ledger_id=#{ledger.id} chequing_id=#{chequing.id}"
    end
  end
end
```

- [ ] **Step 2: Create the global setup**

`tests/support/global-setup.ts`:

```typescript
import { execSync } from "node:child_process"

export default async function globalSetup() {
  const output = execSync("bin/rails playwright:seed", {
    env: { ...process.env, RAILS_ENV: "test" }
  }).toString()
  const match = output.match(/PLAYWRIGHT_SEED user_id=(\d+) ledger_id=(\d+) chequing_id=(\d+)/)
  if (!match) throw new Error(`Seed task did not output expected line:\n${output}`)
  process.env.PLAYWRIGHT_USER_ID = match[1]
  process.env.PLAYWRIGHT_LEDGER_ID = match[2]
  process.env.PLAYWRIGHT_CHEQUING_ID = match[3]
}
```

- [ ] **Step 3: Create the auth helper**

`tests/support/auth.ts`:

```typescript
import type { Page } from "@playwright/test"

export async function login(page: Page) {
  const userId = process.env.PLAYWRIGHT_USER_ID
  if (!userId) throw new Error("PLAYWRIGHT_USER_ID not set; did global setup run?")
  const response = await page.request.get(`/test/login?user_id=${userId}`)
  if (!response.ok()) throw new Error(`Login failed: ${response.status()}`)
}

export function chequingPath(): string {
  return `/accounts/${process.env.PLAYWRIGHT_CHEQUING_ID}`
}
```

- [ ] **Step 4: Update `playwright.config.ts`**

Replace the contents with:

```typescript
import { defineConfig, devices } from "@playwright/test"

export default defineConfig({
  testDir: "./tests",
  fullyParallel: false, // shared DB state
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: "html",
  globalSetup: "./tests/support/global-setup.ts",
  use: {
    baseURL: "http://localhost:3001",
    trace: "on-first-retry"
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } }
  ],
  webServer: {
    command: "bin/rails server -e test -p 3001",
    url: "http://localhost:3001/up",
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
    env: { RAILS_ENV: "test" }
  }
})
```

(Single browser project for now; add firefox/webkit when CI time allows. Workers=1 because the test DB is shared.)

- [ ] **Step 5: Delete the demo spec**

```
git rm tests/example.spec.ts
```

- [ ] **Step 6: Smoke test the wiring**

In one shell:

```
bin/rails db:test:prepare
RAILS_ENV=test bin/rails playwright:seed
```

Expected: prints `PLAYWRIGHT_SEED user_id=… ledger_id=… chequing_id=…`. Capture those numbers; the next test will use them.

- [ ] **Step 7: Commit**

```
git add lib/tasks/playwright.rake tests/support/ playwright.config.ts
git commit -m "Wire up Playwright with webServer, global setup, seed task, and auth helper"
```

---

## Task 19: Playwright spec — basic memo edit

**Files:**
- Create: `tests/transactions/inline_edit.spec.ts`

- [ ] **Step 1: Write the spec**

```typescript
import { test, expect } from "@playwright/test"
import { login, chequingPath } from "../support/auth"

test("editing a memo inline saves on focus leaving the row", async ({ page }) => {
  await login(page)
  await page.goto(chequingPath())

  const groceryRow = page.locator("tr", { hasText: "Weekly groceries" })
  await expect(groceryRow).toBeVisible()

  await groceryRow.click()

  const memoInput = page.locator("input[name='transaction[memo]']")
  await expect(memoInput).toBeVisible()
  await memoInput.fill("Updated memo via Playwright")

  // Click outside the row to trigger blur-to-save.
  await page.locator("h1").first().click()

  await expect(page.locator("tr", { hasText: "Updated memo via Playwright" })).toBeVisible()
  await expect(memoInput).toBeHidden()
})
```

- [ ] **Step 2: Run the spec**

```
yarn playwright test tests/transactions/inline_edit.spec.ts
```

Expected: PASS. If it fails, inspect the trace HTML report for what went wrong.

- [ ] **Step 3: Commit**

```
git add tests/transactions/inline_edit.spec.ts
git commit -m "Playwright: basic memo edit spec"
```

---

## Task 20: Playwright spec — create new payee

**Files:**
- Create: `tests/transactions/inline_edit_payee.spec.ts`

- [ ] **Step 1: Write the spec**

```typescript
import { test, expect } from "@playwright/test"
import { login, chequingPath } from "../support/auth"

test("creating a new payee from the autocomplete persists it", async ({ page }) => {
  await login(page)
  await page.goto(chequingPath())

  const row = page.locator("tr", { hasText: "Weekly groceries" })
  await row.click()

  const payeeInput = page.locator("input[name='transaction[payee_name]']")
  await payeeInput.fill("Brand New Store")

  const createOption = page.locator(".autocomplete-popover li.is-create")
  await expect(createOption).toContainText("Create \"Brand New Store\"")
  await createOption.click()

  await page.locator("h1").first().click() // blur

  await expect(page.locator("tr", { hasText: "Brand New Store" })).toBeVisible()

  // Autocomplete endpoint should now return the new payee.
  const apiResponse = await page.request.get("/payees.json?q=Brand")
  const json = await apiResponse.json()
  expect(json.map((p: { name: string }) => p.name)).toContain("Brand New Store")
})
```

- [ ] **Step 2: Run the spec**

```
yarn playwright test tests/transactions/inline_edit_payee.spec.ts
```

Expected: PASS.

- [ ] **Step 3: Commit**

```
git add tests/transactions/inline_edit_payee.spec.ts
git commit -m "Playwright: create new payee from inline edit"
```

---

## Task 21: Playwright spec — convert transfer to expense via category

**Files:**
- Create: `tests/transactions/inline_edit_category.spec.ts`

- [ ] **Step 1: Write the spec**

```typescript
import { test, expect } from "@playwright/test"
import { login, chequingPath } from "../support/auth"

test("setting a category on a transfer row converts it to an expense", async ({ page }) => {
  await login(page)
  await page.goto(chequingPath())

  const transferRow = page.locator("tr", { hasText: "To savings" })
  await transferRow.click()

  const categoryInput = page.locator("input[name='transaction[category_name]']")
  await categoryInput.fill("Groceries")
  await page.locator(".autocomplete-popover li", { hasText: "Groceries" }).first().click()

  await page.locator("h1").first().click()

  // After conversion, the row should show "Groceries" in the category cell.
  const updatedRow = page.locator("tr", { hasText: "To savings" })
  await expect(updatedRow.locator(".col-cat")).toContainText("Groceries")
})
```

- [ ] **Step 2: Run the spec**

```
yarn playwright test tests/transactions/inline_edit_category.spec.ts
```

Expected: PASS.

- [ ] **Step 3: Commit**

```
git add tests/transactions/inline_edit_category.spec.ts
git commit -m "Playwright: convert transfer to expense via category"
```

---

## Task 22: Playwright spec — validation keeps row in edit mode

**Files:**
- Create: `tests/transactions/inline_edit_validation.spec.ts`

- [ ] **Step 1: Write the spec**

```typescript
import { test, expect } from "@playwright/test"
import { login, chequingPath } from "../support/auth"

test("clearing the date keeps the row in edit mode with an error", async ({ page }) => {
  await login(page)
  await page.goto(chequingPath())

  const row = page.locator("tr", { hasText: "Weekly groceries" })
  await row.click()

  const dateInput = page.locator("input[name='transaction[date]']")
  await dateInput.fill("")
  await page.locator("h1").first().click() // blur

  // Row should still be in edit mode.
  await expect(dateInput).toBeVisible()
  // Field-level error should be present.
  await expect(page.locator("[data-row-edit-form-target='errorDate']")).not.toBeEmpty()
})
```

- [ ] **Step 2: Run the spec**

```
yarn playwright test tests/transactions/inline_edit_validation.spec.ts
```

Expected: PASS.

- [ ] **Step 3: Commit**

```
git add tests/transactions/inline_edit_validation.spec.ts
git commit -m "Playwright: validation error keeps row in edit mode"
```

---

## Task 23: Playwright spec — reconciled row is locked

**Files:**
- Create: `tests/transactions/inline_edit_reconciled.spec.ts`

- [ ] **Step 1: Write the spec**

```typescript
import { test, expect } from "@playwright/test"
import { login, chequingPath } from "../support/auth"

test("clicking a reconciled row does not enter edit mode", async ({ page }) => {
  await login(page)
  await page.goto(chequingPath())

  const reconciledRow = page.locator("tr", { hasText: "Locked rent" })
  await expect(reconciledRow).toHaveAttribute("data-locked", "")

  await reconciledRow.click()

  // No edit form inputs should appear.
  await expect(page.locator("input[name='transaction[memo]']")).toHaveCount(0)
})
```

- [ ] **Step 2: Run the spec**

```
yarn playwright test tests/transactions/inline_edit_reconciled.spec.ts
```

Expected: PASS.

- [ ] **Step 3: Commit**

```
git add tests/transactions/inline_edit_reconciled.spec.ts
git commit -m "Playwright: reconciled row is locked"
```

---

## Task 24: Playwright spec — keyboard behaviour

**Files:**
- Create: `tests/transactions/inline_edit_keyboard.spec.ts`

- [ ] **Step 1: Write the spec**

```typescript
import { test, expect } from "@playwright/test"
import { login, chequingPath } from "../support/auth"

test("Tab between fields stays in edit mode; Enter saves; Escape cancels", async ({ page }) => {
  await login(page)
  await page.goto(chequingPath())

  const row = page.locator("tr", { hasText: "Weekly groceries" })
  await row.click()

  const dateInput = page.locator("input[name='transaction[date]']")
  const memoInput = page.locator("input[name='transaction[memo]']")
  await dateInput.focus()
  await page.keyboard.press("Tab")
  // After tabbing, we should still be in edit mode (some other input still visible).
  await expect(memoInput).toBeVisible()

  // Type a memo and press Enter to save.
  await memoInput.fill("Saved with Enter")
  await memoInput.press("Enter")
  await expect(page.locator("tr", { hasText: "Saved with Enter" })).toBeVisible()

  // Now click into a different row, type, press Escape, expect no save.
  const transferRow = page.locator("tr", { hasText: "To savings" })
  await transferRow.click()
  const transferMemo = page.locator("input[name='transaction[memo]']")
  await transferMemo.fill("Should not persist")
  await transferMemo.press("Escape")
  await expect(page.locator("tr", { hasText: "Should not persist" })).toHaveCount(0)
  await expect(page.locator("tr", { hasText: "To savings" })).toBeVisible()
})
```

- [ ] **Step 2: Run the spec**

```
yarn playwright test tests/transactions/inline_edit_keyboard.spec.ts
```

Expected: PASS.

- [ ] **Step 3: Commit**

```
git add tests/transactions/inline_edit_keyboard.spec.ts
git commit -m "Playwright: keyboard behaviour (Tab, Enter, Escape)"
```

---

## Task 25: Final lint, full test runs, branch summary

**Files:** none modified directly

- [ ] **Step 1: Run rubocop**

```
srt -- bin/rubocop
```

Fix any violations and commit any fixes.

- [ ] **Step 2: Run the full Minitest suite**

```
bin/rails test
```

Expected: all green.

- [ ] **Step 3: Run the full Playwright suite**

```
yarn playwright test
```

Expected: all green.

- [ ] **Step 4: Push and open PR**

```
git push -u origin story/15-inline-editing-transactions
gh pr create --fill --base main
```

(If `git-spice` is the convention for stacked branches, use `gs branch submit` instead.)

- [ ] **Step 5: Mark Vikunja story complete after PR merges**

Once the PR has approved review and is squash-merged into main:

```bash
curl -s -X POST -H "Authorization: Bearer $VIKUNJA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"done": true, "percent_done": 1}' \
  "https://vikunja.landreville.dev/api/v1/tasks/15"
```
