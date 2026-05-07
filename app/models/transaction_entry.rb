class TransactionEntry < ApplicationRecord
  self.table_name = "transactions"

  ENTRY_TYPES = %w[expense income transfer opening_balance].freeze
  STATUSES = %w[uncleared cleared reconciled].freeze

  belongs_to :ledger
  belongs_to :payee, optional: true
  belongs_to :recurring_transaction, optional: true
  has_many :transaction_lines, dependent: :destroy
  accepts_nested_attributes_for :transaction_lines, allow_destroy: true

  validates :date, presence: true
  validates :entry_type, presence: true, inclusion: {in: ENTRY_TYPES}
  validates :status, inclusion: {in: STATUSES}

  validate :lines_sum_to_zero

  private

  def lines_sum_to_zero
    return if transaction_lines.empty?
    total = transaction_lines.sum(:amount)
    errors.add(:base, "transaction lines must sum to zero") unless total.zero?
  end
end
