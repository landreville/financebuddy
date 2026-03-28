require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account" do
    account = Account.new(
      ledger: ledgers(:personal),
      name: "Chequing",
      account_type: "cash",
      on_budget: true
    )
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(ledger: ledgers(:personal), account_type: "cash")
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires account_type" do
    account = Account.new(ledger: ledgers(:personal), name: "Test")
    assert_not account.valid?
    assert_includes account.errors[:account_type], "can't be blank"
  end

  test "validates account_type inclusion" do
    account = Account.new(ledger: ledgers(:personal), name: "Test", account_type: "invalid")
    assert_not account.valid?
    assert_includes account.errors[:account_type], "is not included in the list"
  end

  test "balance defaults to zero" do
    account = Account.new(ledger: ledgers(:personal), name: "Test", account_type: "cash")
    assert_equal 0, account.balance
  end

  test "cleared_balance defaults to zero" do
    account = Account.new(ledger: ledgers(:personal), name: "Test", account_type: "cash")
    assert_equal 0, account.cleared_balance
  end

  test "on_budget defaults to true" do
    account = Account.new(ledger: ledgers(:personal), name: "Test", account_type: "cash")
    assert account.on_budget
  end

  test "archived defaults to false" do
    account = Account.new(ledger: ledgers(:personal), name: "Test", account_type: "cash")
    assert_not account.archived
  end

  test "belongs to ledger" do
    assert_equal ledgers(:personal), accounts(:chequing).ledger
  end

  test "user-facing account types" do
    assert_equal %w[cash credit loan investment], Account::USER_ACCOUNT_TYPES
  end

  test "system account types" do
    assert_equal %w[equity expense revenue], Account::SYSTEM_ACCOUNT_TYPES
  end
end
