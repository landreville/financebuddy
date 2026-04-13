class ReportsController < ApplicationController
  before_action :set_current_ledger

  def index
    @month = params[:month] ? Date.parse(params[:month]) : Date.today.beginning_of_month
    expense_account_ids = @current_ledger.categories.joins(:category_group)
      .where(category_groups: {system_managed: false})
      .pluck(:account_id)
    @spending_by_category = TransactionLine
      .joins(:transaction_entry)
      .joins("INNER JOIN categories ON categories.account_id = transaction_lines.account_id")
      .joins("INNER JOIN category_groups ON category_groups.id = categories.category_group_id")
      .where(
        transactions: {ledger_id: @current_ledger.id, date: @month..@month.end_of_month},
        account_id: expense_account_ids
      )
      .where("transaction_lines.amount > 0")
      .group("category_groups.name", "categories.name")
      .sum("transaction_lines.amount")
      .sort_by { |_, v| -v }
    @total_spending = @spending_by_category.sum { |_, v| v }
  end
end
