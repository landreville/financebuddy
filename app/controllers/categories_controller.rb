class CategoriesController < ApplicationController
  before_action :set_current_ledger

  def index
    query = params[:q] || ""
    categories = @current_ledger.categories.where("name ilike ?", "%#{query}%").order(:name).limit(10).map { |c| { id: c.id, name: c.name } }
    render json: categories
  end
end
