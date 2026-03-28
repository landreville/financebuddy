class ImportEntry < ApplicationRecord
  STATUSES = %w[pending accepted rejected duplicate].freeze
  MATCH_CONFIDENCES = %w[auto potential none].freeze

  belongs_to :ledger
  belongs_to :account
  belongs_to :import_profile, optional: true
  belongs_to :category, optional: true
  belongs_to :matched_transaction, class_name: "TransactionEntry",
    foreign_key: :matched_transaction_id, optional: true

  validates :batch_id, presence: true
  validates :date, presence: true
  validates :amount, presence: true, numericality: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :match_confidence, inclusion: { in: MATCH_CONFIDENCES }, allow_nil: true
end
