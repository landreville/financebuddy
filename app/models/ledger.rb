class Ledger < ApplicationRecord
  has_many :ledger_memberships, dependent: :destroy
  has_many :users, through: :ledger_memberships
  has_many :accounts, dependent: :destroy
  has_many :category_groups, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :payees, dependent: :destroy
  has_many :transaction_entries, dependent: :destroy
  has_many :budget_allocations, dependent: :destroy
  has_many :payee_rules, dependent: :destroy

  validates :name, presence: true
  validates :currency, presence: true

  attribute :currency, default: "CAD"
end
