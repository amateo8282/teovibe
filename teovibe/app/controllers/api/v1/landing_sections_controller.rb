module Api
  module V1
    class LandingSectionsController < ApplicationController
      # 비로그인 방문자가 랜딩페이지를 보므로 인증 불필요
      allow_unauthenticated_access

      def index
        sections = LandingSection.active.ordered.includes(:section_cards)

        render json: sections.as_json(
          only: [:id, :section_type, :title, :subtitle, :background_color, :text_color, :position],
          include: {
            section_cards: {
              only: [:title, :description, :icon, :link_url, :link_text, :position]
            }
          }
        )
      end
    end
  end
end
