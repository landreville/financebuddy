class Payee < ApplicationRecord
  belongs_to :ledger

  has_many :transaction_entries, dependent: :nullify
  has_many :payee_rules, dependent: :destroy

  validates :name, presence: true, uniqueness: {scope: :ledger_id}
end
