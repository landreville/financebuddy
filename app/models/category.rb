class Category < ApplicationRecord
  belongs_to :category_group
  belongs_to :ledger
  belongs_to :account
  belongs_to :credit_card_account, class_name: "Account", optional: true

  has_many :budget_allocations, dependent: :restrict_with_error
  has_many :payee_rules, dependent: :restrict_with_error

  validates :name, presence: true
end
