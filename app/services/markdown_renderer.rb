# 마크다운 텍스트를 HTML로 변환한다 (API로 들어온 본문용).
# Action Text body에 저장되면 렌더 시 한 번 더 살균(sanitize)된다.
# with_toc_data: 헤더에 anchor id를 부여해 목차(TOC) 연결에 사용.
class MarkdownRenderer
  def self.render(text)
    return "" if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      with_toc_data: true,
      hard_wrap: false,
      link_attributes: { rel: "noopener nofollow", target: "_blank" }
    )
    Redcarpet::Markdown.new(
      renderer,
      fenced_code_blocks: true,
      tables: true,
      autolink: true,
      strikethrough: true,
      no_intra_emphasis: true,
      lax_spacing: true,
      space_after_headers: true
    ).render(text.to_s)
  end
end
