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
