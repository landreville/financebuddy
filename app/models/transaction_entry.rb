class TransactionEntry < ApplicationRecord
  self.table_name = "transactions"

  ENTRY_TYPES = %w[expense income transfer opening_balance].freeze
  STATUSES = %w[uncleared cleared reconciled].freeze

  belongs_to :ledger
  belongs_to :payee, optional: true
  belongs_to :recurring_transaction, optional: true
  has_many :transaction_lines, dependent: :destroy

  validates :date, presence: true
  validates :entry_type, presence: true, inclusion: {in: ENTRY_TYPES}
  validates :status, inclusion: {in: STATUSES}
end
