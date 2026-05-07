Rails.application.routes.draw do
  resource :session do
    get "test_login", on: :collection
  end
  resources :passwords, param: :token

  get "up" => "rails/health#show", :as => :rails_health_check

  get "dashboard" => "dashboard#index", as: :dashboard
  get "budget" => "budget#index", as: :budget
  resources :accounts, only: [:index, :show]
  resources :transactions, only: [:update], param: :id
  resources :payees, only: [:index]
  resources :categories, only: [:index]
  get "reports" => "reports#index", as: :reports
  resources :recurring_transactions, only: [:index], path: "recurring"

  root "home#index"
end
