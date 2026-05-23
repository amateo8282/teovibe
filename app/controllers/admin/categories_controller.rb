module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[edit update destroy move_up move_down toggle_admin_only toggle_visible_in_nav]

    def index
      @post_categories = Category.for_posts.ordered
      @skill_pack_categories = Category.for_skill_packs.ordered
    end

    def new
      @category = Category.new(record_type: params[:record_type] || "post")
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path, notice: "카테고리가 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "카테고리가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.destroy
        redirect_to admin_categories_path, notice: "카테고리가 삭제되었습니다.", status: :see_other
      else
        redirect_to admin_categories_path, alert: @category.errors.full_messages.join(", "), status: :see_other
      end
    end

    def reorder
      # positions 배열: [id1, id2, id3, ...] 순서대로 position 일괄 업데이트
      positions = params[:positions] || []
      positions.each_with_index do |id, index|
        Category.where(id: id).update_all(position: index + 1)
      end
      head :ok
    end

    def move_up
      @category.move_up
      redirect_to admin_categories_path
    end

    def move_down
      @category.move_down
      redirect_to admin_categories_path
    end

    def toggle_admin_only
      @category.update!(admin_only: !@category.admin_only)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_categories_path }
      end
    end

    def toggle_visible_in_nav
      @category.update!(visible_in_nav: !@category.visible_in_nav)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_categories_path }
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :slug, :description, :record_type, :admin_only, :visible_in_nav)
    end
  end
end
