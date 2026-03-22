class Account < ApplicationRecord
  enum :account_type, { cash: 0, credit: 1, loan: 2, investment: 3 }
  enum :budget_status, { on_budget: 0, tracking: 1 }

  validates :name, presence: true
  validates :account_type, presence: true
  validates :budget_status, presence: true

  has_many :transaction_entries, dependent: :destroy

  scope :ordered, -> { order(:name) }

  TYPE_LABELS = {
    "cash" => "Cash Account",
    "credit" => "Credit Account",
    "loan" => "Loan Account",
    "investment" => "Investment Account"
  }.freeze

  def display_balance
    if balance.negative?
      "-$#{number_with_delimiter(balance.abs)}"
    else
      "$#{number_with_delimiter(balance)}"
    end
  end

  def negative_balance?
    balance.negative?
  end

  def display_type
    TYPE_LABELS[account_type]
  end

  private

  def number_with_delimiter(number)
    ActiveSupport::NumberHelper.number_to_delimited(
      format("%.2f", number),
      delimiter: ","
    )
  end
end
