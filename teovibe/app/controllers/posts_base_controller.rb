class PostsBaseController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_post!, only: %i[edit update destroy]

  layout "application"

  def index
    @category = category_record
    @posts = @category.posts.published.pinned_first.includes(:user)
    @pagy, @posts = pagy(:offset, @posts, limit: 12)
    render "posts/index"
  end

  def show
    # 본인 글이 아닌 경우에만 조회수 증가
    @post.increment!(:views_count) unless Current.user == @post.user
    @comments = @post.comments.includes(:user).where(parent_id: nil).order(created_at: :asc)
    render "posts/show"
  end

  def new
    @post = Post.new(category: category_record)
    render "posts/new"
  end

  def create
    @post = Current.user.posts.build(post_params.merge(category: category_record, status: :published))
    if @post.save
      redirect_to url_for_post(@post), notice: "글이 작성되었습니다."
    else
      render "posts/new", status: :unprocessable_entity
    end
  end

  def edit
    render "posts/edit"
  end

  def update
    if @post.update(post_params)
      redirect_to url_for_post(@post), notice: "글이 수정되었습니다."
    else
      render "posts/edit", status: :unprocessable_entity
    end
  end

  def destroy
    slug = @post.category&.slug
    @post.destroy
    # slug 기반으로 목록 경로 결정
    list_path = case slug
                when "blog" then blogs_path
                when "tutorial" then tutorials_path
                when "free-board" then free_boards_path
                when "qna" then qnas_path
                when "portfolio" then portfolios_path
                when "notice" then notices_path
                else root_path
                end
    redirect_to list_path, notice: "글이 삭제되었습니다.", status: :see_other
  end

  private

  # 서브클래스에서 Category 레코드를 반환하도록 구현
  def category_record
    raise NotImplementedError
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post!
    unless @post.user == Current.user || Current.user&.admin?
      redirect_to root_path, alert: "권한이 없습니다."
    end
  end

  def post_params
    params.require(:post).permit(:title, :body, :slug, :status, :pinned, :seo_title, :seo_description)
  end

  def url_for_post(post)
    helpers.url_for_post(post)
  end
end
