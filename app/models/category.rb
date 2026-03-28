class Category < ApplicationRecord
  belongs_to :category_group
  belongs_to :ledger
  belongs_to :account
  belongs_to :credit_card_account, class_name: "Account", optional: true

  validates :name, presence: true
end
