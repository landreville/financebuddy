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
  {date: "2026-03-25", amount: 1500, entry_type: :expense, status: :scheduled, payee: "Landlord", category: "Rent", memo: "April rent"},
  {date: "2026-03-22", amount: 52.30, entry_type: :expense, status: :uncleared, payee: "Loblaws", category: "Groceries", memo: "Weekly shop"},
  {date: "2026-03-21", amount: 4.25, entry_type: :expense, status: :cleared, payee: "Tim Hortons", category: "Coffee Shops"},
  {date: "2026-03-20", amount: 3200, entry_type: :income, status: :cleared, payee: "Employer Inc.", memo: "Paycheque"},
  {date: "2026-03-19", amount: 16.99, entry_type: :expense, status: :cleared, payee: "Netflix", category: "Subscriptions"},
  {date: "2026-03-18", amount: 62.40, entry_type: :expense, status: :cleared, payee: "Shell", category: "Gas", memo: "Fill up"},
  {date: "2026-03-15", amount: 187.43, entry_type: :expense, status: :reconciled, payee: "Costco", category: "Groceries", memo: "Bulk run"},
  {date: "2026-03-14", amount: 128, entry_type: :expense, status: :reconciled, payee: "Presto", category: "Public Transit", memo: "Monthly reload"},
  {date: "2026-03-12", amount: 34.99, entry_type: :expense, status: :reconciled, payee: "Canadian Tire", category: "General", memo: "Windshield wipers"},
  {date: "2026-03-10", amount: 22.50, entry_type: :expense, status: :reconciled, payee: "Shoppers Drug Mart", category: "Pharmacy", memo: "Prescription"}
].each do |attrs|
  chequing.transaction_entries.create!(attrs)
end

puts "Seeded #{Account.count} accounts and #{TransactionEntry.count} transactions."
