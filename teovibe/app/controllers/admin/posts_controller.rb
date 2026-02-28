module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[show edit update destroy]

    def index
      @posts = Post.includes(:user).order(created_at: :desc)
      @pagy, @posts = pagy(:offset, @posts, limit: 20)
    end

    def show
    end

    def new
      @post = Post.new
    end

    def create
      @post = Current.user.posts.build(post_params)
      @post.status = :published if @post.status.blank?
      if @post.save
        redirect_to admin_posts_path, notice: "게시글이 작성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @post.update(post_params)
        redirect_to admin_posts_path, notice: "게시글이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "게시글이 삭제되었습니다.", status: :see_other
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :body, :category_id, :status, :pinned, :seo_title, :seo_description)
    end
  end
end
