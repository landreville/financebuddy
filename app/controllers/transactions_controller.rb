class TransactionsController < ApplicationController
  before_action :set_current_ledger
  before_action :set_transaction_entry, only: [:edit, :update]
  before_action :verify_editable, only: [:update]

  def edit
    account_id = params[:account_id] || params[:id]
    @line = @transaction_entry.transaction_lines.find { |l| l.account_id == account_id.to_i }
    @payees = @current_ledger.payees.order(:name)
    @categories = @current_ledger.categories.order(:name)
  end

  def update
    if @transaction_entry.reconciled?
      render turbo_stream: turbo_stream.replace(
        "transaction_#{@transaction_entry.id}",
        partial: "accounts/row",
        locals: { transaction: @transaction_entry }
      )
      return
    end

    updater = TransactionUpdater.new(
      transaction_entry: @transaction_entry,
      attributes: permitted_attributes,
      current_user: current_user
    )

    if updater.update
      render turbo_stream: turbo_stream.replace(
        "transaction_#{@transaction_entry.id}",
        partial: "accounts/row",
        locals: { transaction: updater.transaction_entry }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "transaction_#{@transaction_entry.id}_edit",
        partial: "accounts/edit_row",
        locals: { transaction: @transaction_entry, errors: updater.errors }
      ), status: :unprocessable_entity
    end
  end

  private

  def set_transaction_entry
    @transaction_entry = @current_ledger.transaction_entries.find(params[:id])
  end

  def verify_editable
    head :forbidden if @transaction_entry.reconciled?
  end

  def permitted_attributes
    params.require(:transaction_entry).permit(
      :date,
      :payee_id,
      :memo,
      transaction_lines_attributes: [
        :id,
        :account_id,
        :amount
      ]
    )
  end
end
