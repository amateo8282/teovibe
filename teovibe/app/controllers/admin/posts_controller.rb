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
      handle_scheduling(@post)
      @post.status = :published if @post.status.blank? && !@post.scheduled?
      if @post.save
        enqueue_publish_job(@post) if @post.scheduled?
        redirect_to admin_posts_path, notice: "게시글이 작성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      cancel_existing_job(@post)
      @post.assign_attributes(post_params)
      handle_scheduling(@post)
      if @post.save
        enqueue_publish_job(@post) if @post.scheduled?
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
      # slug 기반 라우팅(to_param → slug)이므로 slug로 조회
      @post = Post.find_by!(slug: params[:id])
    end

    def post_params
      # scheduled_at은 handle_scheduling에서 timezone 변환 후 직접 할당하므로 여기서 제외
      params.require(:post).permit(:title, :body, :category_id, :status, :pinned, :seo_title, :seo_description)
    end

    # 예약 발행 시각 처리 (KST → UTC 변환)
    # params[:post][:scheduled_at]이 있으면 서울 타임존으로 파싱 후 UTC 할당
    # 빈 문자열이면 예약 취소 (scheduled_at = nil)
    def handle_scheduling(post)
      raw = params.dig(:post, :scheduled_at)
      return if raw.nil?

      if raw.blank?
        # 예약 취소
        post.scheduled_at = nil
      else
        # KST로 파싱 후 UTC로 변환하여 저장
        kst_time = ActiveSupport::TimeZone["Seoul"].parse(raw)
        post.scheduled_at = kst_time.utc
        # 예약 지정 시 draft 상태 강제 (발행 전 상태 유지)
        post.status = :draft
      end
    end

    # SolidQueue에 PublishPostJob 등록 후 job_id 저장
    def enqueue_publish_job(post)
      job = PublishPostJob.set(wait_until: post.scheduled_at).perform_later(post.id)
      post.update_column(:job_id, job.provider_job_id)
    end

    # 기존 예약 잡 취소 (scheduled_at 변경/취소 시 이전 잡 삭제)
    def cancel_existing_job(post)
      return unless post.job_id.present?

      SolidQueue::Job.find_by(id: post.job_id)&.destroy
      post.update_column(:job_id, nil)
    end
  end
end
