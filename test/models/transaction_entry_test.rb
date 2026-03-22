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

  test "with_running_balance orders scheduled first then by date desc" do
    entries = accounts(:chequing).transaction_entries.with_running_balance(3147.70)
    statuses = entries.map(&:status)
    scheduled_indices = statuses.each_index.select { |i| statuses[i] == "scheduled" }
    posted_indices = statuses.each_index.select { |i| statuses[i] != "scheduled" }
    assert scheduled_indices.max < posted_indices.min, "Scheduled entries should appear before posted entries" if scheduled_indices.any? && posted_indices.any?
  end

  test "with_running_balance computes running balance via window function" do
    entries = accounts(:chequing).transaction_entries.with_running_balance(3147.70)
    posted = entries.reject(&:scheduled?)

    # First posted entry (newest) should have the current balance
    assert_equal BigDecimal("3147.70"), posted.first.running_balance
  end

  test "with_running_balance returns nil running_balance for scheduled entries" do
    entries = accounts(:chequing).transaction_entries.with_running_balance(3147.70)
    scheduled = entries.select(&:scheduled?)
    scheduled.each do |entry|
      assert_nil entry.running_balance
    end
  end
end
