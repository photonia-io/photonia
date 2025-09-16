# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route
  root 'homepage#index'

  # Devise authentication (skipping all default routes)
  devise_for :users, skip: :all

  # User-related routes
  scope 'users', controller: 'users' do
    get 'sign_in', to: :sign_in, as: :user_sign_in
    get 'sign_out', to: :sign_out, as: :user_sign_out
    get 'settings', to: :settings, as: :user_settings
    get 'admin-settings', to: :admin_settings, as: :user_admin_settings
  end

  # Main resource routes
  resources :photos, except: %i[new] do
    collection do
      get :upload
      get :organizer
      get :deselected
      get :feed, defaults: { format: :xml }
    end
  end

  resources :albums, only: %i[index show] do
    collection do
      get :feed, defaults: { format: :xml }
    end
  end

  resources :tags, only: %i[index show]

  # Statistics
  get 'stats', to: 'stats#index'

  # GraphQL API endpoint
  post 'graphql', to: 'graphql#execute'

  # Static pages
  get 'about', to: 'pages#handler'
  get 'terms-of-service', to: 'pages#handler'
  get 'privacy-policy', to: 'pages#handler'

  # Administrative interfaces - Sidekiq web UI
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV.fetch('PHOTONIA_SIDEKIQ_WEB_USERNAME') &&
      password == ENV.fetch('PHOTONIA_SIDEKIQ_WEB_PASSWORD')
  end

  mount Sidekiq::Web => '/sidekiq'
end
