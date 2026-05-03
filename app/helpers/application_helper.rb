module ApplicationHelper
  def fmt_money(n, sign: false, blank_zero: false)
    return "".html_safe if blank_zero && (!n || n.abs < 0.005)
    abs = number_to_currency(n.abs, unit: "", precision: 2)
    prefix = if sign
      if n < 0
        "-"
      elsif n > 0
        "+"
      else
        " "
      end
    else
      (n < 0) ? "-" : ""
    end
    "#{prefix}$#{abs}".html_safe
  end
end
