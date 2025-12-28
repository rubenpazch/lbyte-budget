# frozen_string_literal: true

Budget::Engine.routes.draw do
  resources :quotes do
    member do
      get :summary
    end

    resources :line_items, only: %i[index show create update destroy]
    resources :payments, only: %i[index show create update destroy]
  end
end
