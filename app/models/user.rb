class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :ledger_memberships, dependent: :destroy
  has_many :ledgers, through: :ledger_memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
