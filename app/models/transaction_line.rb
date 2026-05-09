class TransactionLine < ApplicationRecord
  belongs_to :transaction_entry, foreign_key: :transaction_entry_id
  belongs_to :account

  validates :amount, presence: true, numericality: true

  validate :account_belongs_to_same_ledger, if: :transaction_entry_present?

  private

  def transaction_entry_present?
    transaction_entry_id.present? || transaction_entry
  end

  def account_belongs_to_same_ledger
    return unless transaction_entry
    return unless account
    return if account.ledger_id == transaction_entry.ledger_id
    errors.add(:account, "must belong to the same ledger as the transaction")
  end
end
