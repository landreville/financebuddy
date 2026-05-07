require "test_helper"

class TransactionUpdaterTest < ActiveSupport::TestCase
  def setup
    @ledger = ledgers(:personal)
    @account = accounts(:personal_checking)
    @other_account = accounts(:personal_savings)
    @user = users(:one)
  end

  test "successful update with valid lines" do
    txn = transaction_entries(:grocery_expense)
    line = txn.transaction_lines.first
    original_date = txn.date
    
    updater = TransactionUpdater.new(
      transaction_entry: txn,
      attributes: {
        date: 1.day.from_now.to_date,
        transaction_lines_attributes: [
          { id: line.id, amount: 5000 }
        ]
      },
      current_user: @user
    )
    
    assert updater.update
    assert_equal 1.day.from_now.to_date, txn.reload.date
  end

  test "fails when lines do not sum to zero" do
    txn = transaction_entries(:grocery_expense)
    line = txn.transaction_lines.first
    
    updater = TransactionUpdater.new(
      transaction_entry: txn,
      attributes: {
        transaction_lines_attributes: [
          { id: line.id, amount: 5000 }
        ]
      },
      current_user: @user
    )
    
    assert_not updater.update
    assert_includes updater.errors, "Transaction lines must sum to zero"
  end

  test "fails when updating reconciled transaction" do
    txn = transaction_entries(:grocery_expense)
    txn.update!(status: "reconciled")
    line = txn.transaction_lines.first
    
    updater = TransactionUpdater.new(
      transaction_entry: txn,
      attributes: {
        transaction_lines_attributes: [
          { id: line.id, amount: 1000 }
        ]
      },
      current_user: @user
    )
    
    assert_not updater.update
  end

  test "updates payee" do
    txn = transaction_entries(:grocery_expense)
    payee = payees(:employer)
    
    updater = TransactionUpdater.new(
      transaction_entry: txn,
      attributes: {
        payee_id: payee.id
      },
      current_user: @user
    )
    
    assert updater.update
    assert_equal payee.id, txn.reload.payee_id
  end

  test "updates memo" do
    txn = transaction_entries(:grocery_expense)
    original_memo = txn.memo
    
    updater = TransactionUpdater.new(
      transaction_entry: txn,
      attributes: {
        memo: "New memo"
      },
      current_user: @user
    )
    
    assert updater.update
    assert_equal "New memo", txn.reload.memo
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
          { account_id: @account.id, amount: 1000 },
          { account_id: @other_account.id, amount: -1000 }
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
          { account_id: @account.id, amount: 1000 },
          { account_id: @other_account.id, amount: -1000 }
        ]
      },
      current_user: @user
    )
    
    assert updater.update
    assert_equal "transfer", txn.reload.entry_type
  end
end
