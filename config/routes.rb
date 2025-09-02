Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # TODO endpoints
      resources :todos, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :complete
          patch :uncomplete
        end
        collection do
          get :completed
          get :pending
        end
      end

      # Health check endpoint
      get :health, to: 'health#check'

      # Статистика
      get :stats, to: 'stats#index'
    end

    # Root endpoint
    root 'api/v1/health#check'

    # API documentation endpoint
    get 'api/docs', to: redirect('/api/v1/health')

  end
end
