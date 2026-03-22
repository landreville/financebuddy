class Ledger < ApplicationRecord
  has_many :ledger_memberships, dependent: :destroy
  has_many :users, through: :ledger_memberships

  validates :name, presence: true
  validates :currency, presence: true

  attribute :currency, default: "CAD"
end
