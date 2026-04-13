class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def set_current_ledger
    @current_ledger = Current.user.ledgers.first
    redirect_to root_path, alert: "No ledger found." unless @current_ledger
  end
end
