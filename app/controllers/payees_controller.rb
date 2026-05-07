class PayeesController < ApplicationController
  before_action :set_current_ledger

  def index
    query = params[:q] || ""
    payees = @current_ledger.payees.where("name ilike ?", "%#{query}%").order(:name).limit(10).map { |p| { id: p.id, name: p.name } }
    render json: payees
  end
end
