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
    @transaction_entries = @account.transaction_entries.newest_first

    scheduled = @transaction_entries.scheduled.to_a
    posted = @transaction_entries.posted.to_a

    @ordered_entries = scheduled + posted
    compute_running_balances(@ordered_entries)
  end

  private

  def compute_running_balances(entries)
    balance = @account.balance
    entries.each do |entry|
      entry.instance_variable_set(:@running_balance, balance)
      entry.define_singleton_method(:running_balance) { @running_balance }

      if entry.scheduled?
        next
      end

      if entry.expense?
        balance += entry.amount
      elsif entry.income?
        balance -= entry.amount
      end
    end
  end
end
