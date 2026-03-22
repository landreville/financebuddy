class AccountsController < ApplicationController
  def index
    first_account = Account.on_budget.ordered.first
    if first_account
      redirect_to account_path(first_account)
    else
      redirect_to root_path
    end
  end

  def show
    @account = Account.find(params[:id])
    @accounts = Account.ordered
    @ordered_entries = @account.transaction_entries.with_running_balance(@account.balance)
  end
end
