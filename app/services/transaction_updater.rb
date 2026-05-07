class TransactionUpdater
  attr_reader :transaction_entry, :errors

  def initialize(transaction_entry:, attributes:, current_user:)
    @transaction_entry = transaction_entry
    @attributes = attributes
    @current_user = current_user
    @errors = []
  end

  def update
    return false if locked?

    ApplicationRecord.transaction do
      update_transaction_lines if @attributes.key?(:transaction_lines_attributes)
      update_transaction_entry
      raise ActiveRecord::Rollback if errors.any?
    end

    @transaction_entry.reload
    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.record.errors.full_messages.join(", ")
    false
  end

  private

  def locked?
    @transaction_entry.reconciled?
  end

  def update_transaction_lines
    lines_attrs = @attributes[:transaction_lines_attributes]
    lines_attrs.each do |line_attr|
      if line_attr[:id].present?
        line = @transaction_entry.transaction_lines.find(line_attr[:id])
        line.update!(line_attr.except(:_destroy))
      else
        @transaction_entry.transaction_lines.create!(line_attr)
      end
    end
  end

  def update_transaction_entry
    if @attributes.key?(:payee_id)
      @transaction_entry.payee_id = @attributes[:payee_id]
    end
    if @attributes.key?(:date)
      @transaction_entry.date = @attributes[:date]
    end
    if @attributes.key?(:memo)
      @transaction_entry.memo = @attributes[:memo]
    end

    validate_double_entry
    @transaction_entry.save!
  end

  def validate_double_entry
    total = @transaction_entry.transaction_lines.sum(:amount)
    if total.zero?
      compute_entry_type
    else
      errors << "Transaction lines must sum to zero"
    end
  end

  def compute_entry_type
    lines = @transaction_entry.transaction_lines
    debits = lines.select { |l| l.amount > 0 }
    credits = lines.select { |l| l.amount < 0 }

    if debits.empty? || credits.empty?
      @transaction_entry.entry_type = "transfer"
    elsif debits.all? { |l| l.account.account_type == "expense" } && credits.all? { |l| l.account.account_type == "revenue" }
      @transaction_entry.entry_type = "expense"
    elsif debits.all? { |l| l.account.account_type == "revenue" } && credits.all? { |l| l.account.account_type == "expense" }
      @transaction_entry.entry_type = "income"
    else
      @transaction_entry.entry_type = "transfer"
    end
  end
end
