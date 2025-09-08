Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # User endpoints
      resources :users, only: [:show, :create, :update] do
        collection do
          post :register
        end
        member do
          get :profile
        end
      end

      # Task endpoints
      resources :tasks, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :complete
          patch :uncomplete
        end
        collection do
          get :completed
          get :pending
          get :in_progress
          get :cancelled
        end
      end

      # Category endpoints
      resources :categories, only: [:index, :show, :create, :update, :destroy]

      # Tag endpoints
      resources :tags, only: [:index, :show, :create, :update, :destroy]

      # Health check endpoint
      get :health, to: 'health#check'

      # Stats endpoint
      get :stats, to: 'stats#index'
    end

  end
  
  # API root endpoint
  root 'api/v1/health#check'
end
