class TransactionLine < ApplicationRecord
  belongs_to :transaction_entry, foreign_key: :transaction_entry_id
  belongs_to :account

  validates :amount, presence: true, numericality: true

  validate :account_belongs_to_same_ledger

  private

  def account_belongs_to_same_ledger
    return unless transaction_entry_id_changed?
    return unless account_id.present?
    ledger_id = transaction_entry.ledger_id
    return if account.ledger_id == ledger_id
    errors.add(:account, "must belong to the same ledger as the transaction")
  end
end
