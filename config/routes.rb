# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get '/users/sign_in', to: 'users#sign_in'
  get '/users/sign_out', to: 'users#sign_out'
  get '/users/settings', to: 'users#settings'
  get '/users/admin-settings', to: 'users#admin_settings'

  get '/stats', to: 'stats#index'

  devise_for :users, skip: :all

  resources :photos, except: %i[new] do
    get :upload, on: :collection
    get :organizer, on: :collection
    get :deselected, on: :collection
    get :feed, on: :collection, format: :xml
  end
  resources :tags, only: %i[index show]
  resources :albums, only: %i[index show] do
    get :feed, on: :collection, format: :xml
  end

  post '/graphql', to: 'graphql#execute'

  root 'homepage#index'

  ['about', 'terms-of-service', 'privacy-policy'].each do |page|
    get "/#{page}", to: "pages#handler"
  end

  # sidekiq
  require 'sidekiq/web'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV.fetch('PHOTONIA_SIDEKIQ_WEB_USERNAME') &&
      password == ENV.fetch('PHOTONIA_SIDEKIQ_WEB_PASSWORD')
  end

  mount Sidekiq::Web => '/sidekiq'
end
