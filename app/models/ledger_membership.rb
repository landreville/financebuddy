class LedgerMembership < ApplicationRecord
  belongs_to :ledger
  belongs_to :user

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :ledger_id }
end
