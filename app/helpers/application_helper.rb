module ApplicationHelper
  def fmt_money(n, sign: false, blank_zero: false)
    return "".html_safe if blank_zero && (!n || n.abs < 0.005)
    abs = number_to_currency(n.abs, unit: "", precision: 2)
    if sign
      prefix = n < 0 ? "-" : n > 0 ? "+" : " "
      "#{prefix}$#{abs}".html_safe
    else
      prefix = n < 0 ? "-" : ""
      "#{prefix}$#{abs}".html_safe
    end
  end
end
