# SEO/AEO 최적화 블로그 초안 생성 서비스 (Anthropic Claude API 래퍼)
class AiDraftService
  SYSTEM_PROMPT = <<~PROMPT.freeze
    당신은 SEO와 AEO(Answer Engine Optimization)에 최적화된 한국어 블로그 콘텐츠 전문가입니다.
    콘텐츠 작성 규칙:
    - 제목은 H2/H3 계층 구조로 구성하며, 섹션 제목은 독자의 질문 형태로 작성
    - 각 H2 섹션은 200-400자의 본문을 포함
    - 글 마지막에 FAQ 섹션(H2)을 포함, 5개의 Q&A를 H3으로 구성
    - 답변은 40-60자의 명확한 직접 답변으로 시작
    - 읽기 쉬운 한국어로 작성
    - HTML 태그는 h2, h3, p, ul, li, strong, em만 사용 (div 중첩 금지)
  PROMPT

  def initialize
    @client = Anthropic::Client.new
  end

  # 주제를 기반으로 블로그 개요(outline)를 생성한다
  def generate_outline(topic:)
    message = @client.messages.create(
      model: "claude-sonnet-4-20250514",
      max_tokens: 512,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: "주제: #{topic}\n\nH2 섹션 제목 5-7개로 구성된 블로그 개요를 생성해주세요. " \
                   "각 제목만 줄바꿈으로 구분하여 반환하세요. FAQ 섹션도 포함하세요."
        }
      ]
    )
    message.content.first.text
  end

  # 개요를 기반으로 완성된 블로그 본문을 HTML 형식으로 생성한다
  def generate_body(outline:)
    message = @client.messages.create(
      model: "claude-sonnet-4-20250514",
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: "다음 개요를 기반으로 완성된 블로그 본문을 HTML 형식으로 작성해주세요.\n\n개요:\n#{outline}"
        }
      ]
    )
    message.content.first.text
  end
end
