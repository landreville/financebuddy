class TransactionEntry < ApplicationRecord
  belongs_to :account

  enum :entry_type, { expense: 0, income: 1, transfer: 2 }
  enum :status, { uncleared: 0, cleared: 1, reconciled: 2, scheduled: 3 }

  validates :date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :entry_type, presence: true

  scope :newest_first, -> { order(date: :desc, created_at: :desc) }
  scope :posted, -> { where.not(status: :scheduled) }
  scope :scheduled, -> { where(status: :scheduled) }

  def outflow
    amount if expense? || (transfer? && amount.present?)
  end

  def inflow
    amount if income?
  end

  def display_date
    date.strftime("%Y-%m-%d")
  end

  def display_outflow
    format_currency(outflow) if outflow
  end

  def display_inflow
    format_currency(inflow) if inflow
  end

  private

  def format_currency(value)
    "$#{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', value), delimiter: ',')}"
  end
end
