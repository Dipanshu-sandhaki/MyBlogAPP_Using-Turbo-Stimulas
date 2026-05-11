Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  root "feed#index"

  get "/my-blogs",  to: "blogs#index",  as: :my_blogs
  get "/drafts",    to: "blogs#drafts", as: :drafts

  resources :blogs do
    collection do
      get  :bulk_upload
      post :bulk_create
      delete :bulk_delete
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