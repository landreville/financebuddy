# db/seeds.rb

def status_for(date)
  days_ago = (Date.today - date).to_i
  case days_ago
  when (60..) then "reconciled"
  when (14..) then "cleared"
  else "uncleared"
  end
end

def drift(base, year_index, noise: 0.15)
  cost_of_living = 1.0 + (year_index * 0.015)
  noise_factor = 1.0 + (rand * 2.0 * noise) - noise
  (base * cost_of_living * noise_factor).round(2)
end

def create_expense(ledger:, date:, payee:, category_account:, payment_account:, amount:, memo: nil)
  entry = TransactionEntry.create!(
    ledger: ledger, date: date, payee: payee, memo: memo,
    status: status_for(date), entry_type: "expense", approved: true
  )
  TransactionLine.create!(transaction_entry: entry, account: category_account, amount: amount.round(2))
  TransactionLine.create!(transaction_entry: entry, account: payment_account, amount: -amount.round(2))
end

def create_transfer(ledger:, date:, from_account:, to_account:, amount:, memo: nil)
  entry = TransactionEntry.create!(
    ledger: ledger, date: date, memo: memo,
    status: status_for(date), entry_type: "transfer", approved: true
  )
  TransactionLine.create!(transaction_entry: entry, account: to_account, amount: amount.round(2))
  TransactionLine.create!(transaction_entry: entry, account: from_account, amount: -amount.round(2))
end

def create_income(ledger:, date:, payee:, cash_account:, revenue_account:, amount:, memo: nil)
  entry = TransactionEntry.create!(
    ledger: ledger, date: date, payee: payee, memo: memo,
    status: status_for(date), entry_type: "income", approved: true
  )
  TransactionLine.create!(transaction_entry: entry, account: cash_account, amount: amount.round(2))
  TransactionLine.create!(transaction_entry: entry, account: revenue_account, amount: -amount.round(2))
end

puts "Clearing existing data..."
TransactionLine.destroy_all
TransactionEntry.destroy_all
RecurringTransaction.destroy_all
BudgetAllocation.destroy_all
PayeeRule.destroy_all
Payee.destroy_all
Category.destroy_all
CategoryGroup.destroy_all
Account.destroy_all
LedgerMembership.destroy_all
Session.destroy_all
User.destroy_all
Ledger.destroy_all

puts "Creating ledger and user..."
ledger = Ledger.create!(name: "Demo Budget", currency: "CAD")
user = User.create!(email_address: "demo@example.com", password: "password", password_confirmation: "password")
LedgerMembership.create!(ledger: ledger, user: user, role: "owner")

puts "Creating accounts..."
_opening_balances = Account.create!(
  ledger: ledger, name: "Opening Balances", account_type: "equity",
  on_budget: false, display_order: 0
)
income_account = Account.create!(
  ledger: ledger, name: "Income", account_type: "revenue",
  on_budget: false, display_order: 0
)
chequing = Account.create!(
  ledger: ledger, name: "Northbrook Chequing", account_type: "cash",
  on_budget: true, display_order: 0
)
savings = Account.create!(
  ledger: ledger, name: "Northbrook Savings", account_type: "cash",
  on_budget: true, display_order: 1
)
northbrook_cc = Account.create!(
  ledger: ledger, name: "Northbrook Credit Card", account_type: "credit",
  on_budget: true, display_order: 0
)
summit_visa = Account.create!(
  ledger: ledger, name: "Summit Visa", account_type: "credit",
  on_budget: true, display_order: 1
)
mortgage = Account.create!(
  ledger: ledger, name: "Northbrook Mortgage", account_type: "loan",
  on_budget: false, display_order: 0
)
rrsp = Account.create!(
  ledger: ledger, name: "Northbrook RRSP", account_type: "investment",
  on_budget: false, display_order: 0
)

puts "Creating categories..."
CATEGORY_TAXONOMY = {
  "Housing" => ["Mortgage/Rent", "Property Tax", "Electricity", "Natural Gas", "Internet", "Phone", "House Insurance", "Housekeeping"],
  "Food" => ["Groceries", "Restaurants", "Alcohol"],
  "Transportation" => ["Public Transit", "Gas", "Taxi"],
  "Personal" => ["Pets", "Software", "Miscellaneous"],
  "Recreation" => ["Night/Day Out", "Entertainment"],
  "Savings" => ["Emergency Fund", "Retirement"],
  "Work" => ["Expenses"]
}.freeze

categories = {}
CATEGORY_TAXONOMY.each_with_index do |(group_name, cat_names), group_idx|
  group = CategoryGroup.create!(ledger: ledger, name: group_name, display_order: group_idx)
  cat_names.each_with_index do |cat_name, cat_idx|
    expense_acct = Account.create!(
      ledger: ledger, name: cat_name, account_type: "expense",
      on_budget: false, display_order: cat_idx
    )
    Category.create!(
      ledger: ledger, category_group: group, account: expense_acct,
      name: cat_name, display_order: cat_idx
    )
    categories[cat_name] = expense_acct
  end
end

puts "Creating payees..."
CATEGORY_PAYEES = {
  "Groceries"      => ["Green Valley Market", "Harvest Bulk Foods", "Cedar Farms", "The Cheese Cellar"],
  "Restaurants"    => ["The Corner Diner", "Sunrise Cafe", "Spice Garden", "Noodle House", "The Pizza Co",
                        "QuickBite Delivery", "Harbour Pub", "Morning Brew", "The Sandwich Board"],
  "Alcohol"        => ["The Bottle Shop", "Fine Wine & Spirits"],
  "Public Transit" => ["City Transit"],
  "Gas"            => ["Citywide Fuel"],
  "Taxi"           => ["RideShare"],
  "Internet"       => ["BrightNet"],
  "Phone"          => ["ClearConnect Mobile"],
  "House Insurance"=> ["Maple Shield Insurance"],
  "Electricity"    => ["Northbrook Hydro"],
  "Natural Gas"    => ["City Gas Co."],
  "Property Tax"   => ["Municipal Services"],
  "Housekeeping"   => ["CleanHome Services"],
  "Pets"           => ["Pawsome Pet Store", "Litter & More"],
  "Software"       => ["StreamFlix", "TuneCast", "CloudDrive", "Social Ads", "PrimeMember"],
  "Miscellaneous"  => ["Government Services", "The Pharmacy", "Home Goods", "Online Marketplace"],
  "Entertainment"  => ["The Spa", "City Arena", "Metro Art Gallery"],
  "Night/Day Out"  => ["Harbour Bar", "The Lounge", "Bistro de Ville"],
  "Work"           => ["Work Hotel", "Airport Cafe", "Conference Meals"]
}.freeze

INCOME_PAYEES = ["Meridian Tech Inc.", "E-Transfer Received", "Event Refund"].freeze

payees = {}
(CATEGORY_PAYEES.values.flatten + INCOME_PAYEES).uniq.each do |name|
  payees[name] = Payee.create!(ledger: ledger, name: name)
end

puts "Seeded #{Account.count} accounts, #{Category.count} categories, #{Payee.count} payees."
puts "Generating 60 months of transactions..."

prev_northbrook_cc_spend = 0.0
prev_summit_visa_spend   = 0.0
start_date = Date.new(2021, 4, 1)

60.times do |month_offset|
  date       = start_date >> month_offset
  year       = date.year
  month      = date.month
  year_index = year - 2021

  curr_northbrook_cc_spend = 0.0
  curr_summit_visa_spend   = 0.0

  puts "  #{year}-#{month.to_s.rjust(2, "0")}..." if month == 1 || month_offset == 0

  # Helper lambda: create expense and track CC spending
  add_expense = ->(exp_date, payee, cat_name, payment_account, amount) {
    create_expense(
      ledger: ledger, date: exp_date, payee: payee,
      category_account: categories[cat_name],
      payment_account: payment_account, amount: amount
    )
    curr_northbrook_cc_spend += amount if payment_account == northbrook_cc
    curr_summit_visa_spend   += amount if payment_account == summit_visa
  }

  # ── Income (1st and 15th) ─────────────────────────────────
  create_income(
    ledger: ledger, date: Date.new(year, month, 1),
    payee: payees["Meridian Tech Inc."], cash_account: chequing,
    revenue_account: income_account,
    amount: drift(2750, year_index, noise: 0.02), memo: "Salary deposit"
  )
  create_income(
    ledger: ledger, date: Date.new(year, month, 15),
    payee: payees["Meridian Tech Inc."], cash_account: chequing,
    revenue_account: income_account,
    amount: drift(2750, year_index, noise: 0.02), memo: "Salary deposit"
  )

  # ── Mortgage payment (21st) ───────────────────────────────
  create_transfer(
    ledger: ledger, date: Date.new(year, month, 21),
    from_account: chequing, to_account: mortgage,
    amount: 2500.00, memo: "Mortgage payment"
  )

  # ── Emergency Fund (28th) ─────────────────────────────────
  create_transfer(
    ledger: ledger, date: Date.new(year, month, 28),
    from_account: chequing, to_account: savings,
    amount: drift(400, year_index, noise: 0.20), memo: "Emergency fund"
  )

  # ── Annual RRSP contribution (February only) ──────────────
  if month == 2
    create_transfer(
      ledger: ledger, date: Date.new(year, month, 20),
      from_account: chequing, to_account: rrsp,
      amount: drift(6000, year_index, noise: 0.05), memo: "RRSP contribution"
    )
  end

  # ── CC payments from previous month (5th and 8th) ─────────
  if month_offset > 0 && prev_northbrook_cc_spend > 0.01
    create_transfer(
      ledger: ledger, date: Date.new(year, month, 5),
      from_account: chequing, to_account: northbrook_cc,
      amount: prev_northbrook_cc_spend.round(2), memo: "Credit card payment"
    )
  end
  if month_offset > 0 && prev_summit_visa_spend > 0.01
    create_transfer(
      ledger: ledger, date: Date.new(year, month, 8),
      from_account: chequing, to_account: summit_visa,
      amount: prev_summit_visa_spend.round(2), memo: "Credit card payment"
    )
  end

  # ── Fixed bills on Summit Visa ────────────────────────────
  add_expense.call(Date.new(year, month, 3), payees["BrightNet"],              "Internet",        summit_visa, drift(110, year_index, noise: 0.02))
  add_expense.call(Date.new(year, month, 3), payees["ClearConnect Mobile"],    "Phone",           summit_visa, drift(65,  year_index, noise: 0.02))
  add_expense.call(Date.new(year, month, 3), payees["Maple Shield Insurance"], "House Insurance", summit_visa, drift(105, year_index, noise: 0.02))

  # ── Software subscriptions on Summit Visa (2nd) ───────────
  {"StreamFlix" => 27, "TuneCast" => 14, "CloudDrive" => 22, "Social Ads" => 4, "PrimeMember" => 11}.each do |payee_name, base|
    add_expense.call(Date.new(year, month, 2), payees[payee_name], "Software", summit_visa, drift(base, year_index, noise: 0.03))
  end

  # ── Housekeeping on Northbrook CC (10th) ──────────────────
  add_expense.call(Date.new(year, month, 10), payees["CleanHome Services"], "Housekeeping", northbrook_cc, drift(175, year_index, noise: 0.05))

  # ── Utilities on Chequing ─────────────────────────────────
  electricity_base = [11, 12, 1, 2].include?(month) ? 140 : 90
  gas_base         = [11, 12, 1, 2].include?(month) ? 130 : 60

  create_expense(
    ledger: ledger, date: Date.new(year, month, 9),
    payee: payees["Northbrook Hydro"], category_account: categories["Electricity"],
    payment_account: chequing, amount: drift(electricity_base, year_index, noise: 0.08)
  )
  create_expense(
    ledger: ledger, date: Date.new(year, month, 9),
    payee: payees["City Gas Co."], category_account: categories["Natural Gas"],
    payment_account: chequing, amount: drift(gas_base, year_index, noise: 0.10)
  )
  create_expense(
    ledger: ledger, date: Date.new(year, month, 12),
    payee: payees["Municipal Services"], category_account: categories["Property Tax"],
    payment_account: chequing, amount: drift(650, year_index, noise: 0.01)
  )

  prev_northbrook_cc_spend = curr_northbrook_cc_spend
  prev_summit_visa_spend   = curr_summit_visa_spend
end

puts "Generated #{TransactionEntry.count} transactions so far."
