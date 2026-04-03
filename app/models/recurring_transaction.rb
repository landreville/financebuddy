class RecurringTransaction < ApplicationRecord
  ENTRY_TYPES = %w[expense income transfer].freeze
  FREQUENCIES = %w[weekly biweekly monthly quarterly yearly].freeze

  belongs_to :ledger
  belongs_to :account
  belongs_to :transfer_account, class_name: "Account", optional: true
  belongs_to :payee, optional: true
  belongs_to :category, optional: true
  has_many :transaction_entries, dependent: :nullify

  validates :entry_type, presence: true, inclusion: {in: ENTRY_TYPES}
  validates :amount, presence: true, numericality: {greater_than: 0}
  validates :frequency, presence: true, inclusion: {in: FREQUENCIES}
  validates :start_date, presence: true
  validates :next_due_date, presence: true
end
