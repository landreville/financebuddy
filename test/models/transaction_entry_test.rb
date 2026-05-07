require "test_helper"

class TransactionEntryTest < ActiveSupport::TestCase
  test "valid transaction" do
    txn = TransactionEntry.new(
      ledger: ledgers(:personal),
      date: Date.current,
      entry_type: "expense",
      status: "uncleared"
    )
    assert txn.valid?
  end

  test "requires date" do
    txn = TransactionEntry.new(ledger: ledgers(:personal), entry_type: "expense")
    assert_not txn.valid?
    assert_includes txn.errors[:date], "can't be blank"
  end

  test "requires entry_type" do
    txn = TransactionEntry.new(ledger: ledgers(:personal), date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:entry_type], "can't be blank"
  end

  test "validates entry_type inclusion" do
    txn = TransactionEntry.new(
      ledger: ledgers(:personal), date: Date.current, entry_type: "invalid"
    )
    assert_not txn.valid?
    assert_includes txn.errors[:entry_type], "is not included in the list"
  end

  test "validates status inclusion" do
    txn = TransactionEntry.new(
      ledger: ledgers(:personal), date: Date.current, entry_type: "expense", status: "invalid"
    )
    assert_not txn.valid?
    assert_includes txn.errors[:status], "is not included in the list"
  end

  test "status defaults to uncleared" do
    txn = TransactionEntry.new(ledger: ledgers(:personal), date: Date.current, entry_type: "expense")
    assert_equal "uncleared", txn.status
  end

  test "approved defaults to true" do
    txn = TransactionEntry.new(ledger: ledgers(:personal), date: Date.current, entry_type: "expense")
    assert txn.approved
  end

  test "has many transaction_lines" do
    assert_respond_to transactions(:grocery_expense), :transaction_lines
  end

  test "payee is optional" do
    txn = TransactionEntry.new(
      ledger: ledgers(:personal), date: Date.current, entry_type: "transfer"
    )
    assert txn.valid?
  end

  test "transaction lines must sum to zero" do
    ledger = ledgers(:personal)
    account = accounts(:personal_checking)
    txn = TransactionEntry.new(
      ledger: ledger,
      date: Date.current,
      entry_type: "expense",
      status: "uncleared"
    )
    txn.transaction_lines.build(account: account, amount: 1000)
    txn.transaction_lines.build(account: account, amount: -1000)
    assert txn.valid?
  end

  test "transaction lines that do not sum to zero are invalid" do
    ledger = ledgers(:personal)
    account = accounts(:personal_checking)
    txn = TransactionEntry.new(
      ledger: ledger,
      date: Date.current,
      entry_type: "expense",
      status: "uncleared"
    )
    txn.transaction_lines.build(account: account, amount: 1000)
    txn.transaction_lines.build(account: account, amount: -900)
    assert_not txn.valid?
    assert_includes txn.errors[:base], "transaction lines must sum to zero"
  end

  test "transaction lines must belong to the same ledger as the transaction" do
    ledger = ledgers(:personal)
    other_ledger = ledgers(:household)
    account = accounts(:personal_checking)
    other_account = accounts_by_ledger(:household)[:checking]
    txn = TransactionEntry.new(
      ledger: ledger,
      date: Date.current,
      entry_type: "expense",
      status: "uncleared"
    )
    txn.transaction_lines.build(account: account, amount: 1000)
    txn.transaction_lines.build(account: other_account, amount: -1000)
    assert_not txn.valid?
    assert_includes txn.errors[:account], "must belong to the same ledger as the transaction"
  end
end
