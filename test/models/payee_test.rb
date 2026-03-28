require "test_helper"

class PayeeTest < ActiveSupport::TestCase
  test "valid payee" do
    payee = Payee.new(ledger: ledgers(:personal), name: "Walmart")
    assert payee.valid?
  end

  test "requires name" do
    payee = Payee.new(ledger: ledgers(:personal))
    assert_not payee.valid?
    assert_includes payee.errors[:name], "can't be blank"
  end

  test "requires ledger" do
    payee = Payee.new(name: "Walmart")
    assert_not payee.valid?
  end

  test "enforces unique name per ledger" do
    duplicate = Payee.new(ledger: ledgers(:personal), name: payees(:loblaws).name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end
