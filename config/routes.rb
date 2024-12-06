Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get 'service-worker' => 'rails/pwa#service_worker', as: :pwa_service_worker
  get 'manifest' => 'rails/pwa#manifest', as: :pwa_manifest

  # Defines the root path route ('/')
  root 'static_pages#home'

  get 'feedback' => 'static_pages#feedback'
  get 'signup' => 'users#new'
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  resources :users do
    member do
      patch 'follow_top_sites'
    end
  end

  resources :feeds
  resources :opml, only: %i[new create]
  resources :password_resets
  resources :sessions
  resources :subscriptions
  resources :payments

  get 'success_checkout' => 'payments#success'
  get 'billing_portal' => 'payments#billing_portal'
  post 'webhook' => 'payments#webhook'

  get 'opml/export' => 'opml#export'

  get 'next' => 'subscriptions#next'
end
