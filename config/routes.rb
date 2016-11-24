Rails.application.routes.draw do

  resources :pictures, only: [:index, :create, :destroy]

  root 'pictures#index'
end
