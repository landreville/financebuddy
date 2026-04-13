class RecurringTransactionsController < ApplicationController
  before_action :set_current_ledger

  def index
    @recurring = @current_ledger.recurring_transactions
      .includes(:account, :payee, :category)
      .order(:next_due_date)
  end
end
