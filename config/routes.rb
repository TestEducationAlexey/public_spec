Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: %i[index show create update]

      resources :cards, only: %i[index show]

      resources :shops, only: %i[index show create update] do
        post 'buy', on: :member
      end
    end
  end
end
