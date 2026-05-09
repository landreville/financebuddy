require "test_helper"

class TransactionUpdaterTest < ActiveSupport::TestCase
  def setup
    @ledger = Ledger.create!(name: "Test Ledger", currency: "CAD")
    @user = User.create!(email_address: "test@example.com", password: "password", password_confirmation: "password")
    @account = Account.create!(
      ledger: @ledger,
      name: "Test Chequing",
      account_type: "cash",
      on_budget: true,
      display_order: 0
    )
    @other_account = Account.create!(
      ledger: @ledger,
      name: "Test Savings",
      account_type: "cash",
      on_budget: true,
      display_order: 1
    )

    @txn = TransactionEntry.create!(
      ledger: @ledger,
      date: Date.current,
      entry_type: "expense",
      status: "uncleared"
    )
    @line = TransactionLine.create!(
      transaction_entry: @txn,
      account: @account,
      amount: 1000
    )
    @other_line = TransactionLine.create!(
      transaction_entry: @txn,
      account: @other_account,
      amount: -1000
    )

    @payee = Payee.create!(
      ledger: @ledger,
      name: "Test Payee"
    )
  end

  test "successful update with valid lines" do
    @txn.date

    updater = TransactionUpdater.new(
      transaction_entry: @txn,
      attributes: {
        date: 1.day.from_now.to_date
      },
      current_user: @user
    )

    assert updater.update
    assert_equal 1.day.from_now.to_date, @txn.reload.date
  end

  test "fails when lines do not sum to zero" do
    updater = TransactionUpdater.new(
      transaction_entry: @txn,
      attributes: {
        transaction_lines_attributes: [
          {id: @line.id, amount: 5000}
        ]
      },
      current_user: @user
    )

    assert_not updater.update
    assert_includes updater.errors.join(", "), "Transaction lines must sum to zero"
  end

  test "fails when updating reconciled transaction" do
    @txn.update!(status: "reconciled")

    updater = TransactionUpdater.new(
      transaction_entry: @txn,
      attributes: {
        transaction_lines_attributes: [
          {id: @line.id, amount: 1000}
        ]
      },
      current_user: @user
    )

    assert_not updater.update
  end

  test "updates payee" do
    updater = TransactionUpdater.new(
      transaction_entry: @txn,
      attributes: {
        payee_id: @payee.id
      },
      current_user: @user
    )

    assert updater.update
    assert_equal @payee.id, @txn.reload.payee_id
  end

  test "updates memo" do
    @txn.memo

    updater = TransactionUpdater.new(
      transaction_entry: @txn,
      attributes: {
        memo: "New memo"
      },
      current_user: @user
    )

    assert updater.update
    assert_equal "New memo", @txn.reload.memo
  end

  test "adds new transaction line" do
    txn = TransactionEntry.new(
      ledger: @ledger,
      date: Date.current,
      entry_type: "expense",
      status: "uncleared"
    )
    txn.save!

    updater = TransactionUpdater.new(
      transaction_entry: txn,
      attributes: {
        transaction_lines_attributes: [
          {account_id: @account.id, amount: 1000},
          {account_id: @other_account.id, amount: -1000}
        ]
      },
      current_user: @user
    )

    assert updater.update
    assert_equal 2, txn.reload.transaction_lines.count
  end

  test "computes entry type based on accounts" do
    txn = TransactionEntry.new(
      ledger: @ledger,
      date: Date.current,
      entry_type: "transfer",
      status: "uncleared"
    )
    txn.save!

    updater = TransactionUpdater.new(
      transaction_entry: txn,
      attributes: {
        transaction_lines_attributes: [
          {account_id: @account.id, amount: 1000},
          {account_id: @other_account.id, amount: -1000}
        ]
      },
      current_user: @user
    )

    assert updater.update
    assert_equal "transfer", txn.reload.entry_type
  end
end
