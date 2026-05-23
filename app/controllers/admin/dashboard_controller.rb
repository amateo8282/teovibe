module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.count
      @total_posts = Post.count
      @total_comments = Comment.count
      @recent_posts = Post.includes(:user).order(created_at: :desc).limit(5)
      @recent_users = User.order(created_at: :desc).limit(5)

      # ADMN-01: 조회수 상위 10개 게시글
      @top_posts = Post.where("views_count > 0").order(views_count: :desc).limit(10)
      @top_posts_data = @top_posts.map { |p| [p.title.truncate(30), p.views_count] }

      # ADMN-01: 최근 30일 회원가입 추이
      @registration_trend = User.group_by_day(:created_at, last: 30).count

      # ADMN-01: 좋아요 통계 (상위 10개)
      @top_liked_posts = Post.where("likes_count > 0").order(likes_count: :desc).limit(10)
      @top_liked_data = @top_liked_posts.map { |p| [p.title.truncate(30), p.likes_count] }
    end
  end
end
