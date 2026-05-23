module Admin
  class SectionCardsController < BaseController
    before_action :set_section
    before_action :set_card, only: %i[show edit update destroy]

    def new
      @card = @section.section_cards.build(position: @section.section_cards.maximum(:position).to_i + 1)
    end

    def create
      @card = @section.section_cards.build(card_params)
      if @card.save
        redirect_to admin_landing_section_path(@section), notice: "카드가 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
    end

    def edit
    end

    def update
      if @card.update(card_params)
        redirect_to admin_landing_section_path(@section), notice: "카드가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @card.destroy
      redirect_to admin_landing_section_path(@section), notice: "카드가 삭제되었습니다.", status: :see_other
    end

    private

    def set_section
      @section = LandingSection.find(params[:landing_section_id])
    end

    def set_card
      @card = @section.section_cards.find(params[:id])
    end

    def card_params
      params.require(:section_card).permit(:title, :description, :icon, :link_url, :link_text, :position)
    end
  end
end
