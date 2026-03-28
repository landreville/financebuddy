require "test_helper"

class CategoryGroupTest < ActiveSupport::TestCase
  test "valid category group" do
    group = CategoryGroup.new(ledger: ledgers(:personal), name: "Food & Dining")
    assert group.valid?
  end

  test "requires name" do
    group = CategoryGroup.new(ledger: ledgers(:personal))
    assert_not group.valid?
    assert_includes group.errors[:name], "can't be blank"
  end

  test "requires ledger" do
    group = CategoryGroup.new(name: "Food")
    assert_not group.valid?
  end

  test "has many categories" do
    assert_respond_to category_groups(:food_dining), :categories
  end

  test "system_managed defaults to false" do
    group = CategoryGroup.new(ledger: ledgers(:personal), name: "Test")
    assert_not group.system_managed
  end
end
