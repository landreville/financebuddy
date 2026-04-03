require "test_helper"

class BudgetAllocationTest < ActiveSupport::TestCase
  test "valid budget allocation" do
    allocation = BudgetAllocation.new(
      ledger: ledgers(:personal),
      category: categories(:groceries),
      month: Date.new(2026, 4, 1),
      assigned: 600.00
    )
    assert allocation.valid?
  end

  test "requires ledger" do
    allocation = BudgetAllocation.new(
      category: categories(:groceries), month: Date.new(2026, 4, 1), assigned: 600
    )
    assert_not allocation.valid?
  end

  test "requires category" do
    allocation = BudgetAllocation.new(
      ledger: ledgers(:personal), month: Date.new(2026, 4, 1), assigned: 600
    )
    assert_not allocation.valid?
  end

  test "requires month" do
    allocation = BudgetAllocation.new(
      ledger: ledgers(:personal), category: categories(:groceries), assigned: 600
    )
    assert_not allocation.valid?
    assert_includes allocation.errors[:month], "can't be blank"
  end

  test "assigned defaults to zero" do
    allocation = BudgetAllocation.new(
      ledger: ledgers(:personal),
      category: categories(:groceries),
      month: Date.new(2026, 4, 1)
    )
    assert_equal 0, allocation.assigned
  end

  test "enforces unique category per month" do
    duplicate = BudgetAllocation.new(
      ledger: ledgers(:personal),
      category: budget_allocations(:groceries_march).category,
      month: budget_allocations(:groceries_march).month,
      assigned: 100
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:category_id], "has already been taken"
  end
end
