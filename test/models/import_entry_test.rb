require "test_helper"

class ImportEntryTest < ActiveSupport::TestCase
  test "valid import entry" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal),
      account: accounts(:chequing),
      batch_id: SecureRandom.uuid,
      date: Date.current,
      amount: -52.30,
      status: "pending"
    )
    assert entry.valid?
  end

  test "requires batch_id" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      date: Date.current, amount: -52.30
    )
    assert_not entry.valid?
    assert_includes entry.errors[:batch_id], "can't be blank"
  end

  test "requires date" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      batch_id: "abc", amount: -52.30
    )
    assert_not entry.valid?
    assert_includes entry.errors[:date], "can't be blank"
  end

  test "requires amount" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      batch_id: "abc", date: Date.current
    )
    assert_not entry.valid?
  end

  test "validates status inclusion" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      batch_id: "abc", date: Date.current, amount: -52.30,
      status: "invalid"
    )
    assert_not entry.valid?
    assert_includes entry.errors[:status], "is not included in the list"
  end

  test "status defaults to pending" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      batch_id: "abc", date: Date.current, amount: -52.30
    )
    assert_equal "pending", entry.status
  end

  test "validates match_confidence inclusion when present" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      batch_id: "abc", date: Date.current, amount: -52.30,
      match_confidence: "invalid"
    )
    assert_not entry.valid?
    assert_includes entry.errors[:match_confidence], "is not included in the list"
  end

  test "match_confidence can be nil" do
    entry = ImportEntry.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      batch_id: "abc", date: Date.current, amount: -52.30
    )
    assert entry.valid?
  end
end
