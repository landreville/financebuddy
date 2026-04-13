class BudgetController < ApplicationController
  before_action :set_current_ledger

  def index
    @month = params[:month] ? Date.parse(params[:month]) : Date.today.beginning_of_month
    @category_groups = @current_ledger.category_groups
      .where(system_managed: false, archived: false)
      .includes(categories: :budget_allocations)
      .order(:display_order, :name)
    allocation_ids = @current_ledger.budget_allocations.where(month: @month).pluck(:category_id, :assigned)
    @allocations = allocation_ids.to_h
    expense_account_ids = @current_ledger.categories.pluck(:account_id)
    activity_sums = TransactionLine
      .joins(:transaction_entry)
      .where(
        transactions: {ledger_id: @current_ledger.id, date: @month..@month.end_of_month},
        account_id: expense_account_ids
      )
      .joins("INNER JOIN categories ON categories.account_id = transaction_lines.account_id")
      .group("categories.id")
      .sum("transaction_lines.amount")
    @activity = activity_sums
  end
end
