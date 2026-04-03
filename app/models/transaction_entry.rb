class TransactionEntry < ApplicationRecord
  belongs_to :account

  enum :entry_type, {expense: 0, income: 1, transfer: 2}
  enum :status, {uncleared: 0, cleared: 1, reconciled: 2, scheduled: 3}

  validates :date, presence: true
  validates :amount, presence: true, numericality: {greater_than: 0}
  validates :entry_type, presence: true

  scope :newest_first, -> { order(date: :desc, created_at: :desc) }
  scope :posted, -> { where.not(status: :scheduled) }
  scope :scheduled, -> { where(status: :scheduled) }

  # Returns entries ordered scheduled-first then by date desc, with running_balance
  # computed via Postgres window function. Scheduled entries get NULL running balance.
  scope :with_running_balance, ->(current_balance) {
    scheduled_status = statuses[:scheduled]
    expense_type = entry_types[:expense]
    income_type = entry_types[:income]

    params = {scheduled: scheduled_status, balance: current_balance, expense: expense_type, income: income_type}

    select(
      "transaction_entries.*",
      sanitize_sql_array([
        <<~SQL, params
          CASE WHEN status = :scheduled THEN NULL
          ELSE :balance - COALESCE(
            SUM(
              CASE
                WHEN status != :scheduled AND entry_type = :expense THEN amount
                WHEN status != :scheduled AND entry_type = :income THEN -amount
                ELSE 0
              END
            ) OVER (
              ORDER BY
                CASE WHEN status = :scheduled THEN 1 ELSE 0 END,
                date DESC, created_at DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),
            0
          ) END AS running_balance
        SQL
      ])
    ).order(
      Arel.sql(sanitize_sql_array(["CASE WHEN status = :scheduled THEN 0 ELSE 1 END", params])),
      date: :desc,
      created_at: :desc
    )
  }

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
    "$#{ActiveSupport::NumberHelper.number_to_delimited(format("%.2f", value), delimiter: ",")}"
  end
end
