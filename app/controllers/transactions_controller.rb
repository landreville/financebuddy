class TransactionsController < ApplicationController
  before_action :set_current_ledger
  before_action :set_transaction_entry, only: [:edit, :update]
  before_action :verify_editable, only: [:update]

  def edit
    account_id = params[:account_id] || params[:id]
    @line = @transaction_entry.transaction_lines.find { |l| l.account_id == account_id.to_i }
    @payees = @current_ledger.payees.order(:name)
    @categories = @current_ledger.categories.order(:name)

    unless @line&.account
      head :not_found
      return
    end

    render partial: "accounts/edit_row", locals: {
      transaction: @transaction_entry,
      line: @line,
      account: @line.account,
      payees: @payees,
      categories: @categories
    }
  end

  def update
    account_id = params.dig(:transaction_entry, :account_id)
    unless account_id
      Rails.logger.error "Update failed: account_id is nil for transaction #{@transaction_entry.id}, params: #{params.inspect}"
      head :bad_request
      return
    end

    @line = @transaction_entry.transaction_lines.find { |l| l.account_id == account_id.to_i }
    unless @line
      Rails.logger.error "Update failed: no line found for account_id #{account_id} in transaction #{@transaction_entry.id}"
      head :not_found
      return
    end

    @categories_by_account = @current_ledger.categories.index_by(&:account_id)

    updater = TransactionUpdater.new(
      transaction_entry: @transaction_entry,
      attributes: permitted_attributes,
      current_user: Current.user,
      current_account_id: account_id
    )

    if updater.update
      render turbo_stream: [
        turbo_stream.remove("transaction_#{@transaction_entry.id}_edit_form"),
        turbo_stream.remove("transaction_#{@transaction_entry.id}_edit"),
        turbo_stream.replace(
          "transaction_#{@transaction_entry.id}",
          partial: "accounts/row",
          locals: {
            transaction: updater.transaction_entry,
            account: @line.account,
            line: @line,
            categories_by_account: @categories_by_account
          }
        )
      ]
    else
      render turbo_stream: turbo_stream.replace(
        "transaction_#{@transaction_entry.id}_edit",
        partial: "accounts/edit_row",
        locals: {
          transaction: @transaction_entry,
          line: @line,
          account: @line.account,
          payees: @current_ledger.payees.order(:name),
          categories: @current_ledger.categories.order(:name),
          errors: updater.errors
        }
      ), status: :unprocessable_entity
    end
  end

  private

  def set_transaction_entry
    @transaction_entry = @current_ledger.transaction_entries
      .includes(:payee, transaction_lines: :account)
      .find(params[:id])
  end

  def verify_editable
    head :forbidden if @transaction_entry.reconciled?
  end

  def permitted_attributes
    params.require(:transaction_entry).permit(
      :date,
      :payee_id,
      :memo,
      :category_id,
      transaction_lines_attributes: [
        :id,
        :account_id,
        :amount
      ]
    )
  end
end
