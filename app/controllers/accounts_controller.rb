class AccountsController < ApplicationController
  before_action :set_current_ledger
  before_action :set_sidebar_accounts

  def index
    first = @sidebar_accounts.first
    redirect_to account_path(first) and return if first
  end

  def show
    @account = @current_ledger.accounts.find(params[:id])
    @transactions = @current_ledger.transaction_entries
      .joins(:transaction_lines)
      .where(transaction_lines: {account_id: @account.id})
      .distinct
      .includes(:payee, :transaction_lines)
      .order(date: :desc)
      .limit(100)
    @categories_by_account = @current_ledger.categories.index_by(&:account_id)
    @payees = @current_ledger.payees.order(:name)
    @categories = @current_ledger.categories.order(:name)
  end

  private

  def set_sidebar_accounts
    @sidebar_accounts = @current_ledger.accounts
      .where(account_type: Account::USER_ACCOUNT_TYPES, archived: false)
      .order(:display_order, :name)
  end
end
