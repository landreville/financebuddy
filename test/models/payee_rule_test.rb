require "test_helper"

class PayeeRuleTest < ActiveSupport::TestCase
  test "valid payee rule" do
    rule = PayeeRule.new(
      ledger: ledgers(:personal),
      payee: payees(:loblaws),
      category: categories(:groceries),
      match_type: "exact",
      pattern: "Loblaws"
    )
    assert rule.valid?
  end

  test "requires payee" do
    rule = PayeeRule.new(
      ledger: ledgers(:personal),
      category: categories(:groceries),
      match_type: "exact",
      pattern: "Loblaws"
    )
    assert_not rule.valid?
  end

  test "requires category" do
    rule = PayeeRule.new(
      ledger: ledgers(:personal),
      payee: payees(:loblaws),
      match_type: "exact",
      pattern: "Loblaws"
    )
    assert_not rule.valid?
  end

  test "requires pattern" do
    rule = PayeeRule.new(
      ledger: ledgers(:personal),
      payee: payees(:loblaws),
      category: categories(:groceries),
      match_type: "exact"
    )
    assert_not rule.valid?
    assert_includes rule.errors[:pattern], "can't be blank"
  end

  test "validates match_type inclusion" do
    rule = PayeeRule.new(
      ledger: ledgers(:personal),
      payee: payees(:loblaws),
      category: categories(:groceries),
      match_type: "regex",
      pattern: "Loblaws"
    )
    assert_not rule.valid?
    assert_includes rule.errors[:match_type], "is not included in the list"
  end

  test "match_type defaults to exact" do
    rule = PayeeRule.new(
      ledger: ledgers(:personal),
      payee: payees(:loblaws),
      category: categories(:groceries),
      pattern: "Loblaws"
    )
    assert_equal "exact", rule.match_type
  end
end
