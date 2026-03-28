require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category" do
    # Create a fresh expense account for this test to avoid unique constraint
    fresh_account = Account.create!(
      ledger: ledgers(:personal),
      name: "Test Expense",
      account_type: "expense",
      on_budget: false
    )
    category = Category.new(
      category_group: category_groups(:food_dining),
      ledger: ledgers(:personal),
      account: fresh_account,
      name: "Snacks"
    )
    assert category.valid?
  end

  test "requires name" do
    category = Category.new(
      category_group: category_groups(:food_dining),
      ledger: ledgers(:personal),
      account: accounts(:groceries_expense)
    )
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires category_group" do
    category = Category.new(ledger: ledgers(:personal), name: "Test")
    assert_not category.valid?
  end

  test "requires ledger" do
    category = Category.new(category_group: category_groups(:food_dining), name: "Test")
    assert_not category.valid?
  end

  test "requires account" do
    category = Category.new(
      category_group: category_groups(:food_dining),
      ledger: ledgers(:personal),
      name: "Test"
    )
    assert_not category.valid?
  end

  test "belongs to category_group" do
    assert_equal category_groups(:food_dining), categories(:groceries).category_group
  end

  test "belongs to account (virtual expense account)" do
    assert_equal "expense", categories(:groceries).account.account_type
  end

  test "credit card category references credit card account" do
    assert_equal accounts(:visa), categories(:visa_payment).credit_card_account
  end

  test "system_managed defaults to false" do
    fresh_account = Account.create!(
      ledger: ledgers(:personal),
      name: "Test Expense 2",
      account_type: "expense",
      on_budget: false
    )
    category = Category.new(
      category_group: category_groups(:food_dining),
      ledger: ledgers(:personal),
      account: fresh_account,
      name: "Test"
    )
    assert_not category.system_managed
  end
end
