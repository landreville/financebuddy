# db/seeds.rb

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
