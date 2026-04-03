class PayeeRule < ApplicationRecord
  MATCH_TYPES = %w[exact contains starts_with].freeze

  belongs_to :ledger
  belongs_to :payee
  belongs_to :category

  validates :pattern, presence: true
  validates :match_type, presence: true, inclusion: {in: MATCH_TYPES}

  attribute :match_type, default: "exact"
end
