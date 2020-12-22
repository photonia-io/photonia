Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :photos, only: %i[index show]
  resources :tags, only: %i[index show]
  resources :albums, only: %i[index show]
  root 'homepage#index'
end
