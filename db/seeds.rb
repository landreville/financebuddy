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

puts "Seeded #{Account.count} accounts."
