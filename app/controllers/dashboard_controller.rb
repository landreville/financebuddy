class DashboardController < ApplicationController
  before_action :set_current_ledger

  def index
    @accounts = @current_ledger.accounts
      .where(account_type: Account::USER_ACCOUNT_TYPES, archived: false)
      .order(:display_order, :name)
    @net_worth = @accounts.sum(:balance)
    @recent_transactions = @current_ledger.transaction_entries
      .includes(:payee)
      .order(date: :desc)
      .limit(15)
  end
end
