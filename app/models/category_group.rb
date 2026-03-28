class CategoryGroup < ApplicationRecord
  belongs_to :ledger
  has_many :categories, dependent: :restrict_with_error

  validates :name, presence: true
end
