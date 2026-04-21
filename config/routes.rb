Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # ✅ Feed — home page
  root "feed#index"

  # ✅ My blogs
  get "/my-blogs", to: "blogs#index", as: :my_blogs

  resources :blogs do
    # ✅ Bulk actions (from old code)
    collection do
      get :bulk_upload
      post :bulk_create
      delete :bulk_delete
    end

    # ✅ Likes & Comments
    resources :likes, only: [:create, :destroy]
    resources :comments, only: [:create, :destroy, :update]
  end

  # ✅ Follow / Unfollow
  resources :users, only: [] do
  member do
    post :follow, to: "follows#create"
    delete :unfollow, to: "follows#destroy"
  end
end
end