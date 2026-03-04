Rails.application.routes.draw do
  # 인증
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  # 프로필
  get "me", to: "profiles#show", as: :me
  get "profile/edit", to: "profiles#edit", as: :edit_profile
  patch "profile", to: "profiles#update", as: :profile

  # 소셜 로그인
  get "auth/:provider/callback", to: "omniauth/sessions#create"
  get "auth/failure", to: "omniauth/sessions#failure"

  # SEO 리다이렉트 (301 permanent) — 기존 URL 보존
  get "/blogs",           to: redirect("/posts/blog", status: 301)
  get "/blogs/:id",       to: redirect { |params, _req| "/posts/#{params[:id]}" }
  get "/tutorials",       to: redirect("/posts/tutorial", status: 301)
  get "/tutorials/:id",   to: redirect { |params, _req| "/posts/#{params[:id]}" }
  get "/free-boards",     to: redirect("/posts/free-board", status: 301)
  get "/free-boards/:id", to: redirect { |params, _req| "/posts/#{params[:id]}" }
  get "/qnas",            to: redirect("/posts/qna", status: 301)
  get "/qnas/:id",        to: redirect { |params, _req| "/posts/#{params[:id]}" }
  get "/portfolios",      to: redirect("/posts/portfolio", status: 301)
  get "/portfolios/:id",  to: redirect { |params, _req| "/posts/#{params[:id]}" }
  get "/notices",         to: redirect("/posts/notice", status: 301)
  get "/notices/:id",     to: redirect { |params, _req| "/posts/#{params[:id]}" }

  # 게시글 new/create는 category_slug 와일드카드보다 먼저 선언 (충돌 방지)
  get  "posts/new",  to: "posts#new",    as: :new_post
  post "posts",      to: "posts#create", as: :posts

  # 게시글 CRUD (slug 기반) — new/create는 위에서 선언했으므로 제외
  # constraint: post slug는 숫자 또는 "post-"로 시작 (카테고리 slug와 구분)
  resources :posts, param: :slug, only: %i[show edit update destroy],
            constraints: { slug: /(\d|post-).*/ }

  # 카테고리별 게시글 목록 (post slug constraint 이후에 선언)
  get "posts/:category_slug", to: "posts#index", as: :category_posts

  # 댓글
  resources :comments, only: %i[create destroy] do
    member { patch :accept }
    resource :like, only: %i[create destroy]
  end

  # 좋아요
  resources :posts, param: :slug, only: [] do
    resource :like, only: %i[create destroy]
  end

  # 스킬팩
  resources :skill_packs, only: [:index, :show] do
    member do
      get :download
      get "checkout", to: "checkouts#show", as: :checkout
      get "checkout/success", to: "checkouts#success", as: :checkout_success
      get "checkout/fail", to: "checkouts#fail", as: :checkout_fail
    end
  end
  get "dl/:download_token", to: "skill_packs#token_download", as: :token_download

  # 문의
  resources :inquiries, only: [:new, :create]

  # 알림
  resources :notifications, only: [:index] do
    collection { patch :mark_all_read }
    member { patch :read }
  end

  # 랭킹
  resources :rankings, only: [:index]

  # 포인트 히스토리
  get "me/points", to: "profiles#points", as: :my_points

  # 검색
  get "search", to: "search#index", as: :search
  get "search/suggestions", to: "search#suggestions", as: :search_suggestions

  # 정적 페이지
  get "about", to: "pages#about", as: :about
  get "consulting", to: "pages#consulting", as: :consulting

  # RSS 피드
  get "feed", to: "feeds#index", as: :feed, defaults: { format: :atom }

  # Admin
  namespace :admin do
    root to: "dashboard#index"
    resources :categories, only: %i[index new create edit update destroy] do
      member do
        patch :move_up
        patch :move_down
        patch :toggle_admin_only
        patch :toggle_visible_in_nav
      end
      collection do
        patch :reorder
      end
    end
    resources :landing_sections do
      member do
        patch :move_up
        patch :move_down
        patch :toggle_active
      end
      resources :section_cards, except: %i[index]
    end
    resources :skill_packs
    resources :posts, only: %i[index show new create edit update destroy]
    resources :users, only: %i[index show edit update]
    resources :comments, only: %i[index destroy]
    resources :inquiries, only: [:index, :show, :update] do
      member do
        patch :reply
        patch :close
      end
    end
  end

  # API
  namespace :api do
    namespace :v1 do
      resources :landing_sections, only: [:index]
    end
  end

  # React 데모 (ViewComponent + React 마운트 패턴 검증)
  get "demo/react", to: "demo#react"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # 커스텀 에러 페이지
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all

  # Root
  root "pages#home"
end
