class Payee < ApplicationRecord
  belongs_to :ledger

  has_many :transaction_entries, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :ledger_id }
end
