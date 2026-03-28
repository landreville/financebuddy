require "test_helper"

class ImportProfileTest < ActiveSupport::TestCase
  test "valid import profile" do
    profile = ImportProfile.new(
      ledger: ledgers(:personal),
      account: accounts(:chequing),
      name: "Scotiabank CSV",
      file_format: "csv"
    )
    assert profile.valid?
  end

  test "requires name" do
    profile = ImportProfile.new(
      ledger: ledgers(:personal), account: accounts(:chequing), file_format: "csv"
    )
    assert_not profile.valid?
    assert_includes profile.errors[:name], "can't be blank"
  end

  test "requires file_format" do
    profile = ImportProfile.new(
      ledger: ledgers(:personal), account: accounts(:chequing), name: "Test"
    )
    assert_not profile.valid?
    assert_includes profile.errors[:file_format], "can't be blank"
  end

  test "validates file_format inclusion" do
    profile = ImportProfile.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      name: "Test", file_format: "xlsx"
    )
    assert_not profile.valid?
    assert_includes profile.errors[:file_format], "is not included in the list"
  end

  test "requires account" do
    profile = ImportProfile.new(
      ledger: ledgers(:personal), name: "Test", file_format: "csv"
    )
    assert_not profile.valid?
  end

  test "skip_rows defaults to zero" do
    profile = ImportProfile.new(
      ledger: ledgers(:personal), account: accounts(:chequing),
      name: "Test", file_format: "csv"
    )
    assert_equal 0, profile.skip_rows
  end
end
