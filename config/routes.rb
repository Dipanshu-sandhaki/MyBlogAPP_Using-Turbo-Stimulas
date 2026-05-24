Rails.application.routes.draw do
  
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  resource :profile, only: [:edit, :update]

  root "feed#index"

  get "/my-blogs",  to: "blogs#index",      as: :my_blogs
  get "/drafts",    to: "blogs#drafts",     as: :drafts
  get "/dashboard", to: "dashboards#index", as: :dashboard

  resources :blogs do
    collection do
      get  :bulk_upload
      post :bulk_create
      delete :bulk_delete
    end

    member do
      get  :read
      post :share_email
    end

    resources :likes,    only: [:create, :destroy]
    resources :comments, only: [:create, :destroy, :update]
  end

  resources :users, only: [] do
    member do
      post   :follow,   to: "follows#create"
      delete :unfollow, to: "follows#destroy"
    end
  end
end