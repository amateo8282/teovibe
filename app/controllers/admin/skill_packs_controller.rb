module Admin
  class SkillPacksController < BaseController
    before_action :set_skill_pack, only: [:show, :edit, :update, :destroy]

    def index
      @skill_packs = SkillPack.order(created_at: :desc)
      @pagy, @skill_packs = pagy(:offset, @skill_packs, limit: 20)
    end

    def show
    end

    def new
      @skill_pack = SkillPack.new
    end

    def create
      @skill_pack = SkillPack.new(skill_pack_params)
      if @skill_pack.save
        redirect_to admin_skill_pack_path(@skill_pack), notice: "스킬팩이 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @skill_pack.update(skill_pack_params)
        redirect_to admin_skill_pack_path(@skill_pack), notice: "스킬팩이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @skill_pack.destroy
      redirect_to admin_skill_packs_path, notice: "스킬팩이 삭제되었습니다."
    end

    private

    def set_skill_pack
      @skill_pack = SkillPack.find(params[:id])
    end

    def skill_pack_params
      params.require(:skill_pack).permit(:title, :description, :category_id, :status, :file, :thumbnail)
    end
  end
end
