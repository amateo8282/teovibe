module Admin
  class LandingSectionsController < BaseController
    before_action :set_section, only: %i[show edit update destroy move_up move_down toggle_active]

    def index
      @sections = LandingSection.ordered
    end

    def new
      @section = LandingSection.new(position: LandingSection.maximum(:position).to_i + 1)
    end

    def create
      @section = LandingSection.new(section_params)
      if @section.save
        redirect_to admin_landing_sections_path, notice: "섹션이 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @cards = @section.section_cards.ordered
    end

    def edit
    end

    def update
      if @section.update(section_params)
        redirect_to admin_landing_sections_path, notice: "섹션이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @section.destroy
      redirect_to admin_landing_sections_path, notice: "섹션이 삭제되었습니다.", status: :see_other
    end

    def move_up
      @section.move_up
      redirect_to admin_landing_sections_path
    end

    def move_down
      @section.move_down
      redirect_to admin_landing_sections_path
    end

    def toggle_active
      @section.update(active: !@section.active)
      redirect_to admin_landing_sections_path
    end

    private

    def set_section
      @section = LandingSection.find(params[:id])
    end

    def section_params
      params.require(:landing_section).permit(:section_type, :title, :subtitle, :position, :active, :background_color, :text_color)
    end
  end
end
