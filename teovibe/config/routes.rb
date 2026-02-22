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

  # 게시판 (카테고리별)
  resources :blogs, controller: "blogs"
  resources :tutorials, controller: "tutorials"
  resources :free_boards, controller: "free_boards"
  resources :qnas, controller: "qnas" do
    resources :comments, only: [] do
      member { patch :accept }
    end
  end
  resources :portfolios, controller: "portfolios"
  resources :notices, controller: "notices", only: %i[index show]

  # 게시글 공통 (새 글 작성 시 카테고리 선택)
  resources :posts, only: %i[new create]

  # 댓글
  resources :comments, only: %i[create destroy] do
    resource :like, only: %i[create destroy]
  end

  # 좋아요
  resources :posts, only: [] do
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

  # Root
  root "pages#home"
end
