# Account Register View Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Account Register screen — a sidebar listing financial accounts grouped by budget status/type, and a main area showing the selected account's transaction table.

**Architecture:** Standard Rails MVC. Account and Transaction models with PostgreSQL. Server-rendered views using ERB partials. Turbo Frames for account switching without full page reload. Custom SCSS layered on top of Bootstrap 5. AlpineJS for minor client-side interactivity (collapsible sidebar sections).

**Tech Stack:** Rails 8, PostgreSQL, Bootstrap 5.3, AlpineJS 3, Turbo, Minitest

**Design Spec:** `docs/superpowers/specs/2026-03-22-account-register-design.md`

---

## File Structure

### Models
- `app/models/account.rb` — Account with type enum (cash/credit/loan/investment), budget status enum (on_budget/tracking), name, balance
- `app/models/transaction_entry.rb` — Transaction with date, amount, payee, category, memo, entry_type enum (expense/income/transfer), status enum (uncleared/cleared/reconciled/scheduled). Named `TransactionEntry` to avoid conflict with `ActiveRecord::Base.transaction`.

### Migrations
- `db/migrate/TIMESTAMP_create_accounts.rb`
- `db/migrate/TIMESTAMP_create_transaction_entries.rb`

### Controllers
- `app/controllers/accounts_controller.rb` — `index` (redirects to first account), `show` (renders register for one account)

### Views
- `app/views/layouts/application.html.erb` — Updated with top nav and body structure
- `app/views/shared/_top_nav.html.erb` — Top navigation bar partial
- `app/views/accounts/show.html.erb` — Main register page (sidebar + content)
- `app/views/accounts/_sidebar.html.erb` — Account list sidebar
- `app/views/accounts/_account_header.html.erb` — Selected account header with balance summary
- `app/views/accounts/_transaction_table.html.erb` — Transaction table with rows
- `app/views/accounts/_transaction_row.html.erb` — Single transaction row partial
- `app/views/accounts/_legend_bar.html.erb` — Status legend pinned to bottom

### Stylesheets
- `app/assets/stylesheets/components/_top_nav.scss` — Top nav styles
- `app/assets/stylesheets/components/_sidebar.scss` — Sidebar styles
- `app/assets/stylesheets/components/_transaction_table.scss` — Table styles
- `app/assets/stylesheets/components/_legend_bar.scss` — Legend bar styles
- `app/assets/stylesheets/_variables.scss` — F-Buddy color and typography variables

### Tests
- `test/models/account_test.rb`
- `test/models/transaction_entry_test.rb`
- `test/controllers/accounts_controller_test.rb`
- `test/system/account_register_test.rb`

### Other
- `test/fixtures/accounts.yml`
- `test/fixtures/transaction_entries.yml`
- `db/seeds.rb` — Sample Canadian financial data

---

## Task 1: Add Web Fonts

**Files:**
- Modify: `app/views/layouts/application.html.erb`

Google Fonts provides both Space Grotesk and Inter. Add them via a `<link>` tag in the layout head.

- [ ] **Step 1: Add font link to layout**

In `app/views/layouts/application.html.erb`, add inside `<head>` before the stylesheet tag:

```erb
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Space+Grotesk:wght@400;500;600;700&display=swap" rel="stylesheet">
```

- [ ] **Step 2: Verify fonts load**

Run: `bin/rails server` and open the browser. Inspect the Network tab to confirm the font files load. Stop the server.

- [ ] **Step 3: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "Add Space Grotesk and Inter web fonts via Google Fonts"
```

---

## Task 2: Add F-Buddy SCSS Variables and Component Stylesheets

**Files:**
- Create: `app/assets/stylesheets/_variables.scss`
- Create: `app/assets/stylesheets/components/_top_nav.scss`
- Create: `app/assets/stylesheets/components/_sidebar.scss`
- Create: `app/assets/stylesheets/components/_transaction_table.scss`
- Create: `app/assets/stylesheets/components/_legend_bar.scss`
- Modify: `app/assets/stylesheets/application.bootstrap.scss`

- [ ] **Step 1: Create variables file**

Create `app/assets/stylesheets/_variables.scss`:

```scss
// F-Buddy Color Palette
$fb-nav-bg: #212529;
$fb-sidebar-bg: #f8f9fa;
$fb-content-bg: #ffffff;
$fb-table-header-bg: #f1f3f5;
$fb-zebra-row: #f8f9fa;
$fb-selected-account: #e7f5ff;
$fb-border: #dee2e6;
$fb-scheduled-bg: #fcfcfc;

$fb-text-primary: #212529;
$fb-text-secondary: #868e96;
$fb-text-tertiary: #495057;
$fb-accent-blue: #339af0;
$fb-success-green: #51cf66;
$fb-income-green: #2b8a3e;
$fb-danger-red: #c92a2a;
$fb-muted: #adb5bd;

// Typography
$fb-font-heading: 'Space Grotesk', sans-serif;
$fb-font-body: 'Inter', sans-serif;
```

- [ ] **Step 2: Create top nav styles**

Create `app/assets/stylesheets/components/_top_nav.scss`:

```scss
.fb-top-nav {
  background: $fb-nav-bg;
  height: 48px;
  display: flex;
  align-items: center;
  padding: 0 20px;

  &__brand {
    display: flex;
    align-items: baseline;
    gap: 8px;
    min-width: 160px;
  }

  &__brand-name {
    font-family: $fb-font-heading;
    font-size: 17px;
    font-weight: 700;
    color: #fff;
    text-decoration: none;
    letter-spacing: -0.3px;
  }

  &__brand-tagline {
    font-family: $fb-font-body;
    font-size: 11px;
    font-style: italic;
    color: $fb-text-secondary;
  }

  &__nav {
    display: flex;
    gap: 18px;
    flex: 1;
    justify-content: center;
    align-items: center;
  }

  &__nav-link {
    font-family: $fb-font-heading;
    font-size: 13px;
    font-weight: 500;
    color: $fb-text-secondary;
    text-decoration: none;

    &:hover {
      color: #fff;
    }

    &--active {
      font-weight: 600;
      color: #fff;
      border-bottom: 2px solid $fb-accent-blue;
      padding-bottom: 4px;
    }
  }

  &__actions {
    display: flex;
    gap: 8px;
    min-width: 160px;
    justify-content: flex-end;
    align-items: center;
  }

  &__add-btn {
    font-family: $fb-font-heading;
    font-size: 11px;
    font-weight: 600;
    color: #fff;
    background: $fb-accent-blue;
    border: none;
    border-radius: 4px;
    padding: 4px 10px;
    text-decoration: none;

    &:hover {
      background: darken($fb-accent-blue, 10%);
      color: #fff;
    }
  }

  &__import-link {
    font-family: $fb-font-heading;
    font-size: 11px;
    font-weight: 500;
    color: $fb-text-secondary;
    text-decoration: none;

    &:hover {
      color: #fff;
    }
  }
}
```

- [ ] **Step 3: Create sidebar styles**

Create `app/assets/stylesheets/components/_sidebar.scss`:

```scss
.fb-sidebar {
  width: 220px;
  min-width: 220px;
  background: $fb-sidebar-bg;
  border-right: 1px solid $fb-border;
  padding: 12px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 8px;

  &__section-label {
    font-family: $fb-font-heading;
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;

    &--budget { color: $fb-accent-blue; }
    &--tracking { color: $fb-text-secondary; }
  }

  &__type-label {
    font-family: $fb-font-heading;
    font-size: 10px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: $fb-text-secondary;
  }

  &__account-list {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  &__account-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 4px 6px;
    border-radius: 4px;
    text-decoration: none;
    color: $fb-text-primary;

    &:hover {
      background: #e9ecef;
      color: $fb-text-primary;
    }

    &--selected {
      background: $fb-selected-account;

      .fb-sidebar__account-name { font-weight: 500; }
      .fb-sidebar__account-balance { font-weight: 600; }
    }
  }

  &__account-name {
    font-family: $fb-font-body;
    font-size: 12px;
    font-weight: 400;
  }

  &__account-balance {
    font-family: $fb-font-heading;
    font-size: 12px;
    font-weight: 400;

    &--negative { color: $fb-danger-red; }
  }

  &__group-total {
    font-family: $fb-font-heading;
    font-size: 11px;
    color: $fb-text-secondary;
    text-align: right;
    padding: 2px 6px;

    &--negative { color: $fb-danger-red; }
  }

  &__divider {
    height: 1px;
    background: $fb-border;
  }

  &__net-worth {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 4px 6px;
  }

  &__net-worth-label {
    font-family: $fb-font-heading;
    font-size: 12px;
    font-weight: 600;
    color: $fb-text-primary;
  }

  &__net-worth-value {
    font-family: $fb-font-heading;
    font-size: 12px;
    font-weight: 600;

    &--positive { color: $fb-income-green; }
    &--negative { color: $fb-danger-red; }
  }

  &__account-balance {
    &--positive { color: $fb-text-primary; }
  }
}
```

- [ ] **Step 4: Create transaction table styles**

Create `app/assets/stylesheets/components/_transaction_table.scss`:

```scss
.fb-register {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  background: $fb-content-bg;
}

.fb-account-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid $fb-border;
  flex-shrink: 0;

  &__name {
    font-family: $fb-font-heading;
    font-size: 16px;
    font-weight: 600;
    color: $fb-text-primary;
  }

  &__type {
    font-family: $fb-font-body;
    font-size: 12px;
    color: $fb-text-secondary;
    margin-left: 8px;
  }

  &__balances {
    display: flex;
    gap: 12px;
    align-items: center;
  }

  &__balance-item {
    font-family: $fb-font-body;
    font-size: 12px;
    color: $fb-text-secondary;

    strong {
      font-family: $fb-font-heading;
      font-weight: 600;
      color: $fb-text-primary;
    }
  }

  &__reconcile-btn {
    font-family: $fb-font-heading;
    font-size: 12px;
    font-weight: 500;
    color: $fb-text-tertiary;
    border: 1px solid $fb-border;
    border-radius: 4px;
    padding: 3px 10px;
    background: transparent;

    &:hover {
      background: $fb-sidebar-bg;
    }
  }
}

.fb-table {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;

  &__header {
    display: flex;
    background: $fb-table-header-bg;
    border-bottom: 1px solid $fb-border;
    flex-shrink: 0;
  }

  &__body {
    flex: 1;
    overflow-y: auto;
  }

  &__row {
    display: flex;
    align-items: center;

    &:nth-child(even) {
      background: $fb-zebra-row;
    }

    &:hover {
      background: $fb-table-header-bg;
    }

    &--scheduled {
      opacity: 0.5;
      background: $fb-scheduled-bg;

      &:nth-child(even) { background: $fb-scheduled-bg; }
      &:hover { background: $fb-scheduled-bg; }
    }
  }

  &__cell {
    padding: 3px 8px;
    font-family: $fb-font-body;
    font-size: 12px;
    color: $fb-text-primary;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;

    &--header {
      font-family: $fb-font-heading;
      font-size: 11px;
      font-weight: 600;
      color: $fb-text-tertiary;
      letter-spacing: 0.5px;
      padding: 5px 8px;
    }

    &--status { width: 30px; text-align: center; flex-shrink: 0; }
    &--date { width: 90px; flex-shrink: 0; }
    &--payee { flex: 3; min-width: 0; }
    &--category { flex: 2; min-width: 0; }
    &--memo { flex: 2; min-width: 0; color: $fb-text-secondary; }
    &--outflow { width: 85px; text-align: right; flex-shrink: 0; }
    &--inflow { width: 85px; text-align: right; flex-shrink: 0; }
    &--balance { width: 95px; text-align: right; flex-shrink: 0; }

    &--money {
      font-family: $fb-font-heading;
    }

    &--negative { color: $fb-danger-red; }
    &--positive { color: $fb-income-green; }
  }
}

.fb-status-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;

  &--uncleared {
    border: 1.5px solid $fb-muted;
    background: transparent;
  }

  &--cleared { background: $fb-success-green; }
  &--reconciled { background: $fb-accent-blue; }

  &--scheduled {
    font-family: $fb-font-heading;
    font-size: 9px;
    font-weight: 700;
    color: $fb-muted;
    width: auto;
    height: auto;
    border-radius: 0;
  }
}
```

- [ ] **Step 5: Create legend bar styles**

Create `app/assets/stylesheets/components/_legend_bar.scss`:

```scss
.fb-legend {
  display: flex;
  gap: 16px;
  align-items: center;
  padding: 6px 16px;
  border-top: 1px solid $fb-border;
  background: $fb-content-bg;
  flex-shrink: 0;

  &__item {
    display: flex;
    align-items: center;
    gap: 4px;
    font-family: $fb-font-body;
    font-size: 11px;
    color: $fb-text-secondary;
  }
}
```

- [ ] **Step 6: Import all component stylesheets**

Update `app/assets/stylesheets/application.bootstrap.scss` — add after the existing Bootstrap imports:

```scss
@import "variables";
@import "components/top_nav";
@import "components/sidebar";
@import "components/transaction_table";
@import "components/legend_bar";
```

- [ ] **Step 7: Verify CSS compiles**

Run: `yarn build:css`
Expected: No errors, CSS output includes fb- prefixed rules.

- [ ] **Step 8: Commit**

```bash
git add app/assets/stylesheets/
git commit -m "Add F-Buddy SCSS variables and component stylesheets"
```

---

## Task 3: Create Account Model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_accounts.rb`
- Create: `app/models/account.rb`
- Create: `test/models/account_test.rb`
- Create: `test/fixtures/accounts.yml`

- [ ] **Step 1: Write the model test**

Create `test/models/account_test.rb`:

```ruby
require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account" do
    account = Account.new(
      name: "Chequing",
      account_type: "cash",
      budget_status: "on_budget"
    )
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(account_type: "cash", budget_status: "on_budget")
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires account_type" do
    account = Account.new(name: "Chequing", budget_status: "on_budget")
    assert_not account.valid?
  end

  test "requires budget_status" do
    account = Account.new(name: "Chequing", account_type: "cash")
    assert_not account.valid?
  end

  test "account_type enum values" do
    assert_equal %w[cash credit loan investment], Account.account_types.keys
  end

  test "budget_status enum values" do
    assert_equal %w[on_budget tracking], Account.budget_statuses.keys
  end

  test "balance defaults to zero" do
    account = Account.create!(name: "Test", account_type: "cash", budget_status: "on_budget")
    assert_equal 0, account.balance
  end

  test "scope on_budget" do
    assert_includes Account.on_budget, accounts(:chequing)
    assert_not_includes Account.on_budget, accounts(:mortgage)
  end

  test "scope tracking" do
    assert_includes Account.tracking, accounts(:mortgage)
    assert_not_includes Account.tracking, accounts(:chequing)
  end

  test "scope by_type returns accounts of given type" do
    cash_accounts = Account.where(account_type: :cash)
    assert_includes cash_accounts, accounts(:chequing)
    assert_includes cash_accounts, accounts(:savings)
  end

  test "display_balance formats positive amount" do
    account = Account.new(balance: 3147.70)
    assert_equal "$3,147.70", account.display_balance
  end

  test "display_balance formats negative amount" do
    account = Account.new(balance: -420.15)
    assert_equal "-$420.15", account.display_balance
  end

  test "negative_balance? returns true for negative" do
    assert Account.new(balance: -100).negative_balance?
    assert_not Account.new(balance: 100).negative_balance?
    assert_not Account.new(balance: 0).negative_balance?
  end

  test "display_type returns human-readable type" do
    assert_equal "Cash Account", Account.new(account_type: "cash").display_type
    assert_equal "Credit Account", Account.new(account_type: "credit").display_type
    assert_equal "Loan Account", Account.new(account_type: "loan").display_type
    assert_equal "Investment Account", Account.new(account_type: "investment").display_type
  end
end
```

- [ ] **Step 2: Create fixtures**

Create `test/fixtures/accounts.yml`:

```yaml
chequing:
  name: Chequing
  account_type: cash
  budget_status: on_budget
  balance: 3147.70

savings:
  name: Savings
  account_type: cash
  budget_status: on_budget
  balance: 12500.00

visa:
  name: Visa
  account_type: credit
  budget_status: on_budget
  balance: -420.15

mortgage:
  name: Mortgage
  account_type: loan
  budget_status: tracking
  balance: -285000.00

tfsa:
  name: TFSA
  account_type: investment
  budget_status: tracking
  balance: 8200.00

rrsp:
  name: RRSP
  account_type: investment
  budget_status: tracking
  balance: 22000.00
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bin/rails test test/models/account_test.rb`
Expected: FAIL — table/model does not exist yet.

- [ ] **Step 4: Generate migration**

Run: `bin/rails generate migration CreateAccounts name:string account_type:integer budget_status:integer balance:decimal`

Then edit the generated migration to set precision, defaults, and null constraints:

```ruby
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
```

- [ ] **Step 5: Create model**

Create `app/models/account.rb`:

```ruby
class Account < ApplicationRecord
  enum :account_type, { cash: 0, credit: 1, loan: 2, investment: 3 }
  enum :budget_status, { on_budget: 0, tracking: 1 }

  validates :name, presence: true
  validates :account_type, presence: true
  validates :budget_status, presence: true

  has_many :transaction_entries, dependent: :destroy

  scope :ordered, -> { order(:name) }

  TYPE_LABELS = {
    "cash" => "Cash Account",
    "credit" => "Credit Account",
    "loan" => "Loan Account",
    "investment" => "Investment Account"
  }.freeze

  def display_balance
    if balance.negative?
      "-$#{number_with_delimiter(balance.abs)}"
    else
      "$#{number_with_delimiter(balance)}"
    end
  end

  def negative_balance?
    balance.negative?
  end

  def display_type
    TYPE_LABELS[account_type]
  end

  private

  def number_with_delimiter(number)
    ActiveSupport::NumberHelper.number_to_delimited(
      format("%.2f", number),
      delimiter: ","
    )
  end
end
```

- [ ] **Step 6: Run migration**

Run: `bin/rails db:migrate`
Expected: Migration runs successfully.

- [ ] **Step 7: Run tests**

Run: `bin/rails test test/models/account_test.rb`
Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add db/migrate/ db/schema.rb app/models/account.rb test/models/account_test.rb test/fixtures/accounts.yml
git commit -m "Add Account model with type/budget_status enums and balance"
```

---

## Task 4: Create TransactionEntry Model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_transaction_entries.rb`
- Create: `app/models/transaction_entry.rb`
- Create: `test/models/transaction_entry_test.rb`
- Create: `test/fixtures/transaction_entries.yml`

- [ ] **Step 1: Write the model test**

Create `test/models/transaction_entry_test.rb`:

```ruby
require "test_helper"

class TransactionEntryTest < ActiveSupport::TestCase
  test "valid transaction" do
    txn = TransactionEntry.new(
      account: accounts(:chequing),
      date: Date.new(2026, 3, 22),
      amount: 52.30,
      entry_type: "expense",
      status: "uncleared",
      payee: "Loblaws"
    )
    assert txn.valid?
  end

  test "requires account" do
    txn = TransactionEntry.new(date: Date.today, amount: 10, entry_type: "expense", status: "uncleared")
    assert_not txn.valid?
    assert_includes txn.errors[:account], "must exist"
  end

  test "requires date" do
    txn = TransactionEntry.new(account: accounts(:chequing), amount: 10, entry_type: "expense", status: "uncleared")
    assert_not txn.valid?
  end

  test "requires amount" do
    txn = TransactionEntry.new(account: accounts(:chequing), date: Date.today, entry_type: "expense", status: "uncleared")
    assert_not txn.valid?
  end

  test "amount must be positive" do
    txn = TransactionEntry.new(
      account: accounts(:chequing), date: Date.today,
      amount: -10, entry_type: "expense", status: "uncleared"
    )
    assert_not txn.valid?
    assert_includes txn.errors[:amount], "must be greater than 0"
  end

  test "entry_type enum values" do
    assert_equal %w[expense income transfer], TransactionEntry.entry_types.keys
  end

  test "status enum values" do
    assert_equal %w[uncleared cleared reconciled scheduled], TransactionEntry.statuses.keys
  end

  test "scope newest_first orders by date descending" do
    txns = accounts(:chequing).transaction_entries.newest_first
    dates = txns.map(&:date)
    assert_equal dates.sort.reverse, dates
  end

  test "outflow returns amount for expense" do
    txn = TransactionEntry.new(amount: 52.30, entry_type: "expense")
    assert_equal 52.30, txn.outflow
    assert_nil txn.inflow
  end

  test "inflow returns amount for income" do
    txn = TransactionEntry.new(amount: 3200, entry_type: "income")
    assert_nil txn.outflow
    assert_equal 3200, txn.inflow
  end

  test "display_date formats as YYYY-MM-DD" do
    txn = TransactionEntry.new(date: Date.new(2026, 3, 22))
    assert_equal "2026-03-22", txn.display_date
  end

  test "display_outflow formats currency" do
    txn = TransactionEntry.new(amount: 52.30, entry_type: "expense")
    assert_equal "$52.30", txn.display_outflow
  end

  test "display_inflow formats currency" do
    txn = TransactionEntry.new(amount: 3200, entry_type: "income")
    assert_equal "$3,200.00", txn.display_inflow
  end
end
```

- [ ] **Step 2: Create fixtures**

Create `test/fixtures/transaction_entries.yml`:

```yaml
loblaws:
  account: chequing
  date: "2026-03-22"
  amount: 52.30
  entry_type: expense
  status: uncleared
  payee: Loblaws
  category: Groceries
  memo: Weekly shop

tim_hortons:
  account: chequing
  date: "2026-03-21"
  amount: 4.25
  entry_type: expense
  status: cleared
  payee: Tim Hortons
  category: Coffee Shops

paycheque:
  account: chequing
  date: "2026-03-20"
  amount: 3200.00
  entry_type: income
  status: cleared
  payee: Employer Inc.
  memo: Paycheque

netflix:
  account: chequing
  date: "2026-03-19"
  amount: 16.99
  entry_type: expense
  status: cleared
  payee: Netflix
  category: Subscriptions

shell:
  account: chequing
  date: "2026-03-18"
  amount: 62.40
  entry_type: expense
  status: cleared
  payee: Shell
  category: Gas
  memo: Fill up

costco:
  account: chequing
  date: "2026-03-15"
  amount: 187.43
  entry_type: expense
  status: reconciled
  payee: Costco
  category: Groceries
  memo: Bulk run

rent_scheduled:
  account: chequing
  date: "2026-03-25"
  amount: 1500.00
  entry_type: expense
  status: scheduled
  payee: Landlord
  category: Rent
  memo: April rent
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bin/rails test test/models/transaction_entry_test.rb`
Expected: FAIL — table/model does not exist yet.

- [ ] **Step 4: Generate migration**

Run: `bin/rails generate migration CreateTransactionEntries`

Edit the generated migration:

```ruby
class CreateTransactionEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.integer :entry_type, null: false
      t.integer :status, null: false, default: 0
      t.string :payee
      t.string :category
      t.string :memo

      t.timestamps
    end

    add_index :transaction_entries, [:account_id, :date]
    add_index :transaction_entries, :status
  end
end
```

- [ ] **Step 5: Create model**

Create `app/models/transaction_entry.rb`:

```ruby
class TransactionEntry < ApplicationRecord
  belongs_to :account

  enum :entry_type, { expense: 0, income: 1, transfer: 2 }
  enum :status, { uncleared: 0, cleared: 1, reconciled: 2, scheduled: 3 }

  validates :date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :entry_type, presence: true

  scope :newest_first, -> { order(date: :desc, created_at: :desc) }
  scope :posted, -> { where.not(status: :scheduled) }
  scope :scheduled, -> { where(status: :scheduled) }

  def outflow
    amount if expense? || (transfer? && amount.present?)
  end

  def inflow
    amount if income?
  end

  def display_date
    date.strftime("%Y-%m-%d")
  end

  def display_outflow
    format_currency(outflow) if outflow
  end

  def display_inflow
    format_currency(inflow) if inflow
  end

  private

  def format_currency(value)
    "$#{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', value), delimiter: ',')}"
  end
end
```

- [ ] **Step 6: Run migration**

Run: `bin/rails db:migrate`
Expected: Migration runs successfully.

- [ ] **Step 7: Run tests**

Run: `bin/rails test test/models/transaction_entry_test.rb`
Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add db/migrate/ db/schema.rb app/models/transaction_entry.rb test/models/transaction_entry_test.rb test/fixtures/transaction_entries.yml
git commit -m "Add TransactionEntry model with entry_type/status enums"
```

---

## Task 5: Create Accounts Controller and Routes

**Files:**
- Create: `app/controllers/accounts_controller.rb`
- Modify: `config/routes.rb`
- Create: `test/controllers/accounts_controller_test.rb`

- [ ] **Step 1: Write the controller test**

Create `test/controllers/accounts_controller_test.rb`:

```ruby
require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "index redirects to first on_budget account" do
    get accounts_path
    assert_redirected_to account_path(accounts(:chequing))
  end

  test "show renders the account register" do
    get account_path(accounts(:chequing))
    assert_response :success
    assert_select ".fb-sidebar"
    assert_select ".fb-account-header"
    assert_select ".fb-table"
  end

  test "show displays account name" do
    get account_path(accounts(:chequing))
    assert_select ".fb-account-header__name", "Chequing"
  end

  test "show displays transactions for the account" do
    get account_path(accounts(:chequing))
    assert_select ".fb-table__row"
  end

  test "show loads all accounts in sidebar" do
    get account_path(accounts(:chequing))
    assert_select ".fb-sidebar__account-row", count: Account.count
  end

  test "show displays empty state when account has no transactions" do
    get account_path(accounts(:savings))
    assert_select "p", text: "No transactions yet"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/accounts_controller_test.rb`
Expected: FAIL — controller/routes do not exist.

- [ ] **Step 3: Create controller**

Create `app/controllers/accounts_controller.rb`:

```ruby
class AccountsController < ApplicationController
  def index
    first_account = Account.on_budget.ordered.first
    if first_account
      redirect_to account_path(first_account)
    else
      redirect_to root_path
    end
  end

  def show
    @account = Account.find(params[:id])
    @accounts = Account.ordered
    @transaction_entries = @account.transaction_entries.newest_first

    scheduled = @transaction_entries.scheduled.to_a
    posted = @transaction_entries.posted.to_a

    @ordered_entries = scheduled + posted
    compute_running_balances(@ordered_entries)
  end

  private

  def compute_running_balances(entries)
    balance = @account.balance
    entries.each do |entry|
      entry.instance_variable_set(:@running_balance, balance)
      entry.define_singleton_method(:running_balance) { @running_balance }

      if entry.scheduled?
        next
      end

      if entry.expense?
        balance += entry.amount
      elsif entry.income?
        balance -= entry.amount
      end
    end
  end
end
```

Note: Running balance is computed top-down from the current balance. Since transactions are sorted newest-first, we add back expenses and subtract income to walk backward. Scheduled transactions don't affect the running balance.

- [ ] **Step 4: Add routes**

Update `config/routes.rb`, add before the root line:

```ruby
resources :accounts, only: [:index, :show]
```

- [ ] **Step 5: Run tests (will fail — views missing)**

Run: `bin/rails test test/controllers/accounts_controller_test.rb`
Expected: FAIL — views not yet created. This is expected; views come in the next task.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/accounts_controller.rb config/routes.rb test/controllers/accounts_controller_test.rb
git commit -m "Add Accounts controller with index redirect and show action"
```

---

## Task 6: Create Views — Layout and Top Nav

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Create: `app/views/shared/_top_nav.html.erb`

- [ ] **Step 1: Create top nav partial**

Create `app/views/shared/_top_nav.html.erb`:

```erb
<nav class="fb-top-nav">
  <div class="fb-top-nav__brand">
    <%= link_to "F-Buddy", root_path, class: "fb-top-nav__brand-name" %>
    <span class="fb-top-nav__brand-tagline">F as in finance</span>
  </div>

  <div class="fb-top-nav__nav">
    <%= link_to "Dashboard", "#", class: "fb-top-nav__nav-link" %>
    <%= link_to "Budget", "#", class: "fb-top-nav__nav-link" %>
    <%= link_to "Accounts", accounts_path, class: "fb-top-nav__nav-link #{'fb-top-nav__nav-link--active' if controller_name == 'accounts'}" %>
    <%= link_to "Reports", "#", class: "fb-top-nav__nav-link" %>
    <%= link_to "Recurring", "#", class: "fb-top-nav__nav-link" %>
  </div>

  <div class="fb-top-nav__actions">
    <%= link_to "+ Transaction", "#", class: "fb-top-nav__add-btn" %>
    <%= link_to "Import", "#", class: "fb-top-nav__import-link" %>
  </div>
</nav>
```

- [ ] **Step 2: Update application layout**

Replace the `<body>` content in `app/views/layouts/application.html.erb` with:

```erb
<body>
  <div class="d-flex flex-column vh-100">
    <%= render "shared/top_nav" %>
    <div class="d-flex flex-grow-1" style="min-height: 0;">
      <%= yield %>
    </div>
  </div>
</body>
```

- [ ] **Step 3: Commit**

```bash
git add app/views/layouts/application.html.erb app/views/shared/_top_nav.html.erb
git commit -m "Add application layout with F-Buddy top navigation bar"
```

---

## Task 7: Create Views — Account Register

**Files:**
- Create: `app/views/accounts/show.html.erb`
- Create: `app/views/accounts/_sidebar.html.erb`
- Create: `app/views/accounts/_account_header.html.erb`
- Create: `app/views/accounts/_transaction_table.html.erb`
- Create: `app/views/accounts/_transaction_row.html.erb`
- Create: `app/views/accounts/_legend_bar.html.erb`
- Create: `app/helpers/accounts_helper.rb`

- [ ] **Step 1: Create accounts helper**

Create `app/helpers/accounts_helper.rb`:

```ruby
module AccountsHelper
  def grouped_accounts(accounts)
    {
      on_budget: {
        cash: accounts.select { |a| a.on_budget? && a.cash? },
        credit: accounts.select { |a| a.on_budget? && a.credit? }
      },
      tracking: {
        loan: accounts.select { |a| a.tracking? && a.loan? },
        investment: accounts.select { |a| a.tracking? && a.investment? }
      }
    }
  end

  def group_total(accounts)
    accounts.sum(&:balance)
  end

  def format_balance(amount)
    if amount.negative?
      "-$#{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', amount.abs), delimiter: ',')}"
    else
      "$#{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', amount), delimiter: ',')}"
    end
  end

  def balance_css_class(amount)
    if amount.negative?
      "fb-sidebar__account-balance--negative"
    elsif amount.positive?
      "fb-sidebar__account-balance--positive"
    else
      ""
    end
  end

  def net_worth_css_class(amount)
    if amount.negative?
      "fb-sidebar__net-worth-value--negative"
    elsif amount.positive?
      "fb-sidebar__net-worth-value--positive"
    else
      ""
    end
  end

  def account_balance_summary(account)
    entries = account.transaction_entries.where.not(status: :scheduled)
    cleared_entries = entries.where(status: [:cleared, :reconciled])
    uncleared_entries = entries.where(status: :uncleared)

    cleared = compute_net_amount(cleared_entries)
    uncleared = compute_net_amount(uncleared_entries)

    { cleared: cleared, uncleared: uncleared, balance: account.balance }
  end

  private

  def compute_net_amount(entries)
    income = entries.where(entry_type: :income).sum(:amount)
    expenses = entries.where(entry_type: :expense).sum(:amount)
    income - expenses
  end

  def running_balance_css_class(entry)
    return "" unless entry.respond_to?(:running_balance) && entry.running_balance
    entry.running_balance.negative? ? "fb-table__cell--negative" : ""
  end
end
```

- [ ] **Step 2: Create sidebar partial**

Create `app/views/accounts/_sidebar.html.erb`:

```erb
<% groups = grouped_accounts(@accounts) %>

<aside class="fb-sidebar">
  <span class="fb-sidebar__section-label fb-sidebar__section-label--budget">On-Budget</span>

  <% { "Cash" => groups[:on_budget][:cash], "Credit" => groups[:on_budget][:credit] }.each do |type_name, type_accounts| %>
    <% next if type_accounts.empty? %>
    <span class="fb-sidebar__type-label"><%= type_name %></span>
    <div class="fb-sidebar__account-list">
      <% type_accounts.each do |account| %>
        <%= link_to account_path(account),
            class: "fb-sidebar__account-row #{'fb-sidebar__account-row--selected' if account == @account}" do %>
          <span class="fb-sidebar__account-name"><%= account.name %></span>
          <span class="fb-sidebar__account-balance <%= balance_css_class(account.balance) %>">
            <%= account.display_balance %>
          </span>
        <% end %>
      <% end %>
    </div>
    <div class="fb-sidebar__group-total <%= 'fb-sidebar__group-total--negative' if group_total(type_accounts).negative? %>">
      <%= format_balance(group_total(type_accounts)) %>
    </div>
  <% end %>

  <div class="fb-sidebar__divider"></div>

  <span class="fb-sidebar__section-label fb-sidebar__section-label--tracking">Tracking</span>

  <% { "Loans" => groups[:tracking][:loan], "Investments" => groups[:tracking][:investment] }.each do |type_name, type_accounts| %>
    <% next if type_accounts.empty? %>
    <span class="fb-sidebar__type-label"><%= type_name %></span>
    <div class="fb-sidebar__account-list">
      <% type_accounts.each do |account| %>
        <%= link_to account_path(account),
            class: "fb-sidebar__account-row #{'fb-sidebar__account-row--selected' if account == @account}" do %>
          <span class="fb-sidebar__account-name"><%= account.name %></span>
          <span class="fb-sidebar__account-balance <%= balance_css_class(account.balance) %>">
            <%= account.display_balance %>
          </span>
        <% end %>
      <% end %>
    </div>
    <div class="fb-sidebar__group-total <%= 'fb-sidebar__group-total--negative' if group_total(type_accounts).negative? %>">
      <%= format_balance(group_total(type_accounts)) %>
    </div>
  <% end %>

  <div class="fb-sidebar__divider"></div>

  <div class="fb-sidebar__net-worth">
    <span class="fb-sidebar__net-worth-label">Net Worth</span>
    <% net_worth = @accounts.sum(&:balance) %>
    <span class="fb-sidebar__net-worth-value <%= net_worth_css_class(net_worth) %>">
      <%= format_balance(net_worth) %>
    </span>
  </div>
</aside>
```

- [ ] **Step 3: Create account header partial**

Create `app/views/accounts/_account_header.html.erb`:

```erb
<div class="fb-account-header">
  <div>
    <span class="fb-account-header__name"><%= @account.name %></span>
    <span class="fb-account-header__type"><%= @account.display_type %></span>
  </div>

  <div class="fb-account-header__balances">
    <% summary = account_balance_summary(@account) %>
    <span class="fb-account-header__balance-item">
      Cleared: <strong><%= format_balance(summary[:cleared]) %></strong>
    </span>
    <span class="fb-account-header__balance-item">
      Uncleared: <strong><%= format_balance(summary[:uncleared]) %></strong>
    </span>
    <span class="fb-account-header__balance-item">
      Balance: <strong><%= @account.display_balance %></strong>
    </span>
    <button class="fb-account-header__reconcile-btn">Reconcile</button>
  </div>
</div>
```

- [ ] **Step 4: Create transaction row partial**

Create `app/views/accounts/_transaction_row.html.erb`:

```erb
<div class="fb-table__row <%= 'fb-table__row--scheduled' if entry.scheduled? %>">
  <div class="fb-table__cell fb-table__cell--status">
    <% if entry.scheduled? %>
      <span class="fb-status-dot fb-status-dot--scheduled">S</span>
    <% else %>
      <span class="fb-status-dot fb-status-dot--<%= entry.status %>"></span>
    <% end %>
  </div>
  <div class="fb-table__cell fb-table__cell--date"><%= entry.display_date %></div>
  <div class="fb-table__cell fb-table__cell--payee"><%= entry.payee %></div>
  <div class="fb-table__cell fb-table__cell--category"><%= entry.category.presence || "—" %></div>
  <div class="fb-table__cell fb-table__cell--memo"><%= entry.memo %></div>
  <div class="fb-table__cell fb-table__cell--outflow fb-table__cell--money <%= 'fb-table__cell--negative' if entry.display_outflow %>">
    <%= entry.display_outflow %>
  </div>
  <div class="fb-table__cell fb-table__cell--inflow fb-table__cell--money <%= 'fb-table__cell--positive' if entry.display_inflow %>">
    <%= entry.display_inflow %>
  </div>
  <div class="fb-table__cell fb-table__cell--balance fb-table__cell--money <%= running_balance_css_class(entry) %>">
    <% if entry.respond_to?(:running_balance) && entry.running_balance %>
      <%= format_balance(entry.running_balance) %>
    <% end %>
  </div>
</div>
```

- [ ] **Step 5: Create transaction table partial**

Create `app/views/accounts/_transaction_table.html.erb`:

```erb
<div class="fb-table">
  <div class="fb-table__header">
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--status"></div>
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--date">Date</div>
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--payee">Payee</div>
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--category">Category</div>
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--memo">Memo</div>
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--outflow">Outflow</div>
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--inflow">Inflow</div>
    <div class="fb-table__cell fb-table__cell--header fb-table__cell--balance">Balance</div>
  </div>

  <div class="fb-table__body">
    <% if @ordered_entries.empty? %>
      <div class="d-flex align-items-center justify-content-center h-100">
        <div class="text-center">
          <p style="font-family: Inter, sans-serif; font-size: 14px; color: #868e96;">No transactions yet</p>
          <p style="font-family: Inter, sans-serif; font-size: 12px; color: #adb5bd;">Click + Transaction to add your first one.</p>
        </div>
      </div>
    <% else %>
      <% @ordered_entries.each do |entry| %>
        <%= render "transaction_row", entry: entry %>
      <% end %>
    <% end %>
  </div>
</div>
```

- [ ] **Step 6: Create legend bar partial**

Create `app/views/accounts/_legend_bar.html.erb`:

```erb
<div class="fb-legend">
  <span class="fb-legend__item">
    <span class="fb-status-dot fb-status-dot--uncleared"></span>
    Uncleared
  </span>
  <span class="fb-legend__item">
    <span class="fb-status-dot fb-status-dot--cleared"></span>
    Cleared
  </span>
  <span class="fb-legend__item">
    <span class="fb-status-dot fb-status-dot--reconciled"></span>
    Reconciled
  </span>
  <span class="fb-legend__item">
    <span class="fb-status-dot fb-status-dot--scheduled">S</span>
    Scheduled
  </span>
</div>
```

- [ ] **Step 7: Create main show view**

Create `app/views/accounts/show.html.erb`:

```erb
<%= render "sidebar" %>

<div class="fb-register">
  <%= render "account_header" %>
  <%= render "transaction_table" %>
  <%= render "legend_bar" %>
</div>
```

- [ ] **Step 8: Run controller tests**

Run: `bin/rails test test/controllers/accounts_controller_test.rb`
Expected: All tests PASS.

- [ ] **Step 9: Commit**

```bash
git add app/views/accounts/ app/views/shared/ app/helpers/accounts_helper.rb
git commit -m "Add Account Register views: sidebar, header, table, and legend"
```

---

## Task 8: Add Seed Data

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Write seed data**

Update `db/seeds.rb`:

```ruby
puts "Clearing existing data..."
TransactionEntry.destroy_all
Account.destroy_all

puts "Creating accounts..."
chequing = Account.create!(name: "Chequing", account_type: :cash, budget_status: :on_budget, balance: 3147.70)
Account.create!(name: "Savings", account_type: :cash, budget_status: :on_budget, balance: 12500.00)
Account.create!(name: "Visa", account_type: :credit, budget_status: :on_budget, balance: -420.15)
Account.create!(name: "Mortgage", account_type: :loan, budget_status: :tracking, balance: -285000.00)
Account.create!(name: "TFSA", account_type: :investment, budget_status: :tracking, balance: 8200.00)
Account.create!(name: "RRSP", account_type: :investment, budget_status: :tracking, balance: 22000.00)

puts "Creating transactions for Chequing..."
[
  { date: "2026-03-25", amount: 1500, entry_type: :expense, status: :scheduled, payee: "Landlord", category: "Rent", memo: "April rent" },
  { date: "2026-03-22", amount: 52.30, entry_type: :expense, status: :uncleared, payee: "Loblaws", category: "Groceries", memo: "Weekly shop" },
  { date: "2026-03-21", amount: 4.25, entry_type: :expense, status: :cleared, payee: "Tim Hortons", category: "Coffee Shops" },
  { date: "2026-03-20", amount: 3200, entry_type: :income, status: :cleared, payee: "Employer Inc.", memo: "Paycheque" },
  { date: "2026-03-19", amount: 16.99, entry_type: :expense, status: :cleared, payee: "Netflix", category: "Subscriptions" },
  { date: "2026-03-18", amount: 62.40, entry_type: :expense, status: :cleared, payee: "Shell", category: "Gas", memo: "Fill up" },
  { date: "2026-03-15", amount: 187.43, entry_type: :expense, status: :reconciled, payee: "Costco", category: "Groceries", memo: "Bulk run" },
  { date: "2026-03-14", amount: 128, entry_type: :expense, status: :reconciled, payee: "Presto", category: "Public Transit", memo: "Monthly reload" },
  { date: "2026-03-12", amount: 34.99, entry_type: :expense, status: :reconciled, payee: "Canadian Tire", category: "General", memo: "Windshield wipers" },
  { date: "2026-03-10", amount: 22.50, entry_type: :expense, status: :reconciled, payee: "Shoppers Drug Mart", category: "Pharmacy", memo: "Prescription" },
].each do |attrs|
  chequing.transaction_entries.create!(attrs)
end

puts "Seeded #{Account.count} accounts and #{TransactionEntry.count} transactions."
```

- [ ] **Step 2: Run seeds**

Run: `bin/rails db:seed`
Expected: Output shows 6 accounts and 10 transactions created.

- [ ] **Step 3: Commit**

```bash
git add db/seeds.rb
git commit -m "Add seed data with sample Canadian accounts and transactions"
```

---

## Task 9: System Test — Account Register

**Files:**
- Create: `test/system/account_register_test.rb`

- [ ] **Step 1: Write system test**

Create `test/system/account_register_test.rb`:

```ruby
require "application_system_test_case"

class AccountRegisterTest < ApplicationSystemTestCase
  test "visiting accounts shows the register" do
    visit accounts_path

    # Should redirect to first on-budget account (Chequing)
    assert_selector ".fb-top-nav"
    assert_selector ".fb-sidebar"
    assert_selector ".fb-account-header__name", text: "Chequing"
  end

  test "sidebar shows accounts grouped by budget status" do
    visit account_path(accounts(:chequing))

    within ".fb-sidebar" do
      # Section/type labels render mixed-case in DOM; CSS text-transform handles uppercase visually
      assert_selector ".fb-sidebar__section-label--budget", text: "On-Budget"
      assert_selector ".fb-sidebar__type-label", text: "Cash"
      assert_text "Chequing"
      assert_text "Savings"
      assert_selector ".fb-sidebar__type-label", text: "Credit"
      assert_text "Visa"
      assert_selector ".fb-sidebar__section-label--tracking", text: "Tracking"
      assert_selector ".fb-sidebar__type-label", text: "Loans"
      assert_text "Mortgage"
      assert_selector ".fb-sidebar__type-label", text: "Investments"
      assert_text "TFSA"
      assert_text "RRSP"
      assert_text "Net Worth"
    end
  end

  test "transaction table shows entries" do
    visit account_path(accounts(:chequing))

    within ".fb-table__body" do
      assert_text "Loblaws"
      assert_text "Groceries"
      assert_text "$52.30"
    end
  end

  test "legend bar is visible" do
    visit account_path(accounts(:chequing))

    within ".fb-legend" do
      assert_text "Uncleared"
      assert_text "Cleared"
      assert_text "Reconciled"
      assert_text "Scheduled"
    end
  end

  test "clicking another account switches the register" do
    visit account_path(accounts(:chequing))

    within ".fb-sidebar" do
      click_link "Savings"
    end

    assert_selector ".fb-account-header__name", text: "Savings"
  end

  test "top nav highlights Accounts" do
    visit account_path(accounts(:chequing))

    assert_selector ".fb-top-nav__nav-link--active", text: "Accounts"
  end
end
```

- [ ] **Step 2: Run system tests**

Run: `bin/rails test test/system/account_register_test.rb`
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add test/system/account_register_test.rb
git commit -m "Add system tests for Account Register view"
```

---

## Task 10: Run Full Test Suite and Final Verification

- [ ] **Step 1: Run all tests**

Run: `bin/rails test`
Expected: All tests pass (model, controller, system).

- [ ] **Step 2: Visual verification**

Run: `bin/rails db:seed && bin/rails server`
Open `http://localhost:3000/accounts` in a browser. Verify:
- Top nav shows "F-Buddy" with tagline, centered nav, quick actions
- Sidebar shows accounts grouped by On-Budget/Tracking with totals
- Chequing account is selected with blue highlight
- Transaction table shows all sample data with correct status dots
- Zebra striping on alternating rows
- Legend bar pinned at bottom
- Clicking another account loads its register

- [ ] **Step 3: Stop server and commit any fixes**

If any visual fixes are needed, make them and commit.

- [ ] **Step 4: Run full test suite one final time**

Run: `bin/rails test`
Expected: All tests PASS.
