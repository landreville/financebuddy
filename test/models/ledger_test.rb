require "test_helper"

class LedgerTest < ActiveSupport::TestCase
  test "valid ledger" do
    ledger = Ledger.new(name: "Test Budget", currency: "CAD")
    assert ledger.valid?
  end

  test "requires name" do
    ledger = Ledger.new(name: nil, currency: "CAD")
    assert_not ledger.valid?
    assert_includes ledger.errors[:name], "can't be blank"
  end

  test "requires currency" do
    ledger = Ledger.new(name: "Test", currency: nil)
    assert_not ledger.valid?
    assert_includes ledger.errors[:currency], "can't be blank"
  end

  test "currency defaults to CAD" do
    ledger = Ledger.new(name: "Test")
    assert_equal "CAD", ledger.currency
  end

  test "has many memberships" do
    assert_respond_to ledgers(:personal), :ledger_memberships
  end

  test "has many users through memberships" do
    assert_respond_to ledgers(:personal), :users
  end
end
