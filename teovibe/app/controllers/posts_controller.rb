class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_post!, only: %i[edit update destroy]

  layout "application"

  # GET /posts/:category_slug
  def index
    @category = Category.find_by!(slug: params[:category_slug], record_type: :post)
    @posts = @category.posts.published.pinned_first.includes(:user)
    @pagy, @posts = pagy(:offset, @posts, limit: 12)
  end

  # GET /posts/:slug
  def show
    # 본인 글이 아닌 경우에만 조회수 증가
    @post.increment!(:views_count) unless Current.user == @post.user
    @comments = @post.comments.includes(:user).where(parent_id: nil).order(created_at: :asc)
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # POST /posts
  def create
    @post = Current.user.posts.build(post_params)
    if @post.save
      redirect_to post_path(@post), notice: "글이 작성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /posts/:slug/edit
  def edit
  end

  # PATCH/PUT /posts/:slug
  def update
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/:slug
  def destroy
    category_slug = @post.category&.slug
    @post.destroy
    redirect_to category_posts_path(category_slug: category_slug), notice: "글이 삭제되었습니다.", status: :see_other
  end

  private

  def set_post
    @post = Post.find_by!(slug: params[:slug])
  end

  def authorize_post!
    unless @post.user == Current.user || Current.user&.admin?
      redirect_to root_path, alert: "권한이 없습니다."
    end
  end

  def post_params
    params.require(:post).permit(:title, :body, :category_id, :slug, :status, :pinned, :seo_title, :seo_description)
  end
end
