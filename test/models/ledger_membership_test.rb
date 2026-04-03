require "test_helper"

class LedgerMembershipTest < ActiveSupport::TestCase
  test "valid membership" do
    membership = LedgerMembership.new(
      ledger: ledgers(:business),
      user: users(:jason),
      role: "member"
    )
    assert membership.valid?
  end

  test "requires ledger" do
    membership = LedgerMembership.new(user: users(:jason), role: "owner")
    assert_not membership.valid?
  end

  test "requires user" do
    membership = LedgerMembership.new(ledger: ledgers(:personal), role: "owner")
    assert_not membership.valid?
  end

  test "requires role" do
    membership = LedgerMembership.new(ledger: ledgers(:personal), user: users(:jason), role: nil)
    assert_not membership.valid?
  end

  test "enforces unique user per ledger" do
    duplicate = LedgerMembership.new(
      ledger: ledger_memberships(:jason_personal).ledger,
      user: ledger_memberships(:jason_personal).user,
      role: "member"
    )
    assert_not duplicate.valid?
  end
end
