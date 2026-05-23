class SearchController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q].to_s.strip
    if @query.present?
      # FTS5 전문 검색
      post_ids = Post.connection.select_values(
        Post.sanitize_sql(["SELECT rowid FROM posts_fts WHERE posts_fts MATCH ?", fts_query(@query)])
      )

      if post_ids.any?
        @posts = Post.published.where(id: post_ids).includes(:user).order(created_at: :desc)
      else
        # FTS5 매치 없으면 LIKE 폴백 (ActionText 본문 포함)
        @posts = Post.published
          .left_joins(:rich_text_body)
          .where(
            "posts.title LIKE :q OR posts.slug LIKE :q OR action_text_rich_texts.body LIKE :q",
            q: "%#{@query}%"
          )
          .includes(:user)
          .order(created_at: :desc)
      end

      @pagy, @posts = pagy(:offset, @posts, limit: 12)
    else
      @posts = Post.none
    end
  end

  def suggestions
    query = params[:q].to_s.strip
    if query.length >= 2
      # FTS5 prefix 검색으로 자동완성
      results = Post.connection.select_all(
        Post.sanitize_sql([
          "SELECT rowid FROM posts_fts WHERE posts_fts MATCH ? LIMIT 5",
          "#{fts_query(query)}*"
        ])
      )
      post_ids = results.map { |r| r["rowid"] }
      @suggestions = Post.published.where(id: post_ids).limit(5).pluck(:title)
    else
      @suggestions = []
    end

    render json: @suggestions
  end

  private

  # FTS5 쿼리 안전 변환 (특수문자 이스케이프)
  def fts_query(query)
    # FTS5 특수문자 제거 후 공백으로 AND 검색
    query.gsub(/[^가-힣a-zA-Z0-9\s]/, "").strip
  end
end
