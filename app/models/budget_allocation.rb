class BudgetAllocation < ApplicationRecord
  belongs_to :ledger
  belongs_to :category

  validates :month, presence: true
  validates :category_id, uniqueness: { scope: :month }
end
