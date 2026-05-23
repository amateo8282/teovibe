module PostsHelper
  # 렌더된 본문 HTML의 h2/h3에 anchor id를 주입하고, 목차(TOC) 항목을 함께 반환한다.
  # Action Text 살균기가 id를 떼어내므로 렌더 시점(여기)에서 주입한다.
  # 반환: [body_html(html_safe), toc_entries]  (toc_entries: [{level:, text:, id:}, ...])
  def post_body_with_toc(rich_text)
    return ["".html_safe, []] if rich_text.blank?

    fragment = Nokogiri::HTML.fragment(rich_text.to_s)
    entries = []

    fragment.css("h2, h3").each_with_index do |node, i|
      text = node.text.strip
      next if text.empty?

      id = "toc-#{i + 1}"
      node["id"] = id
      node["class"] = [ node["class"], "scroll-mt-24" ].compact.join(" ")
      entries << { level: node.name[1].to_i, text: text, id: id }
    end

    [ fragment.to_html.html_safe, entries ]
  end
end
