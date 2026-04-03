require "test_helper"

class TransactionLineTest < ActiveSupport::TestCase
  test "valid transaction line" do
    line = TransactionLine.new(
      transaction_entry: transactions(:grocery_expense),
      account: accounts(:chequing),
      amount: -52.30
    )
    assert line.valid?
  end

  test "requires transaction_entry" do
    line = TransactionLine.new(account: accounts(:chequing), amount: -52.30)
    assert_not line.valid?
  end

  test "requires account" do
    line = TransactionLine.new(
      transaction_entry: transactions(:grocery_expense), amount: -52.30
    )
    assert_not line.valid?
  end

  test "requires amount" do
    line = TransactionLine.new(
      transaction_entry: transactions(:grocery_expense),
      account: accounts(:chequing)
    )
    assert_not line.valid?
    assert_includes line.errors[:amount], "is not a number"
  end

  test "amount can be negative" do
    line = TransactionLine.new(
      transaction_entry: transactions(:grocery_expense),
      account: accounts(:chequing),
      amount: -100.00
    )
    assert line.valid?
  end

  test "amount can be positive" do
    line = TransactionLine.new(
      transaction_entry: transactions(:grocery_expense),
      account: accounts(:groceries_expense),
      amount: 100.00
    )
    assert line.valid?
  end

  test "belongs to transaction_entry" do
    assert_equal transactions(:grocery_expense),
      transaction_lines(:grocery_chequing_line).transaction_entry
  end

  test "belongs to account" do
    assert_equal accounts(:chequing),
      transaction_lines(:grocery_chequing_line).account
  end
end
