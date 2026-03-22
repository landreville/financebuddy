module AccountsHelper
  def grouped_accounts(accounts)
    {
      on_budget: {
        cash: accounts.select { |a| a.on_budget? && a.cash? },
        credit: accounts.select { |a| a.on_budget? && a.credit? }
      },
      tracking: {
        loan: accounts.select { |a| a.tracking? && a.loan? },
        investment: accounts.select { |a| a.tracking? && a.investment? }
      }
    }
  end

  def group_total(accounts)
    accounts.sum(&:balance)
  end

  def format_balance(amount)
    if amount.negative?
      "-$#{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', amount.abs), delimiter: ',')}"
    else
      "$#{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', amount), delimiter: ',')}"
    end
  end

  def balance_css_class(amount)
    if amount.negative?
      "fb-sidebar__account-balance--negative"
    elsif amount.positive?
      "fb-sidebar__account-balance--positive"
    else
      ""
    end
  end

  def net_worth_css_class(amount)
    if amount.negative?
      "fb-sidebar__net-worth-value--negative"
    elsif amount.positive?
      "fb-sidebar__net-worth-value--positive"
    else
      ""
    end
  end

  def account_balance_summary(account)
    entries = account.transaction_entries.where.not(status: :scheduled)
    cleared_entries = entries.where(status: [:cleared, :reconciled])
    uncleared_entries = entries.where(status: :uncleared)

    cleared = compute_net_amount(cleared_entries)
    uncleared = compute_net_amount(uncleared_entries)

    { cleared: cleared, uncleared: uncleared, balance: account.balance }
  end

  def running_balance_css_class(entry)
    return "" unless entry.respond_to?(:running_balance) && entry.running_balance
    entry.running_balance.negative? ? "fb-table__cell--negative" : ""
  end

  private

  def compute_net_amount(entries)
    income = entries.where(entry_type: :income).sum(:amount)
    expenses = entries.where(entry_type: :expense).sum(:amount)
    income - expenses
  end
end
