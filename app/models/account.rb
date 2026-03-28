class Account < ApplicationRecord
  USER_ACCOUNT_TYPES = %w[cash credit loan investment].freeze
  SYSTEM_ACCOUNT_TYPES = %w[equity expense revenue].freeze
  ACCOUNT_TYPES = (USER_ACCOUNT_TYPES + SYSTEM_ACCOUNT_TYPES).freeze

  belongs_to :ledger
  has_one :category, dependent: :nullify

  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: ACCOUNT_TYPES }
end
