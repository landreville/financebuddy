require "test_helper"

class RecurringTransactionTest < ActiveSupport::TestCase
  test "valid recurring transaction" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal),
      account: accounts(:chequing),
      entry_type: "expense",
      amount: 1500.00,
      frequency: "monthly",
      start_date: Date.new(2026, 1, 1),
      next_due_date: Date.new(2026, 4, 1)
    )
    assert rt.valid?
  end

  test "requires account" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), entry_type: "expense",
      amount: 100, frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert_not rt.valid?
  end

  test "requires entry_type" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      amount: 100, frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert_not rt.valid?
    assert_includes rt.errors[:entry_type], "can't be blank"
  end

  test "validates entry_type inclusion" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "opening_balance", amount: 100, frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert_not rt.valid?
    assert_includes rt.errors[:entry_type], "is not included in the list"
  end

  test "requires amount" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert_not rt.valid?
  end

  test "amount must be positive" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", amount: -100, frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert_not rt.valid?
    assert_includes rt.errors[:amount], "must be greater than 0"
  end

  test "validates frequency inclusion" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", amount: 100, frequency: "daily",
      start_date: Date.current, next_due_date: Date.current
    )
    assert_not rt.valid?
    assert_includes rt.errors[:frequency], "is not included in the list"
  end

  test "requires start_date" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", amount: 100, frequency: "monthly",
      next_due_date: Date.current
    )
    assert_not rt.valid?
    assert_includes rt.errors[:start_date], "can't be blank"
  end

  test "requires next_due_date" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", amount: 100, frequency: "monthly",
      start_date: Date.current
    )
    assert_not rt.valid?
    assert_includes rt.errors[:next_due_date], "can't be blank"
  end

  test "end_date is optional" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", amount: 100, frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert rt.valid?
    assert_nil rt.end_date
  end

  test "auto_enter defaults to false" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", amount: 100, frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert_not rt.auto_enter
  end

  test "transfer_account is optional" do
    rt = RecurringTransaction.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      entry_type: "expense", amount: 100, frequency: "monthly",
      start_date: Date.current, next_due_date: Date.current
    )
    assert rt.valid?
  end
end
