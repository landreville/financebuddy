class TransactionLine < ApplicationRecord
  belongs_to :transaction_entry, foreign_key: :transaction_entry_id
  belongs_to :account

  validates :amount, presence: true, numericality: true
end
