module Admin
  # AI 초안 생성 JSON API 컨트롤러 (Admin 전용)
  # AIDR-01: POST /admin/ai_draft/outline → { outline: string }
  # AIDR-02: POST /admin/ai_draft/body    → { body_html: string }
  # AIDR-03: 에러 발생 시 { error: string } + 422
  class AiDraftsController < BaseController
    def outline
      service = AiDraftService.new
      outline_text = service.generate_outline(topic: params[:topic])
      render json: { outline: outline_text }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def body
      service = AiDraftService.new
      body_html = service.generate_body(outline: params[:outline])
      render json: { body_html: body_html }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
