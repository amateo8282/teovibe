# ActionText 렌더링 시 style 속성과 table 관련 태그를 보존하도록 허용목록 확장
# 보안 주의: math 태그는 절대 추가하지 말 것 (CVE-2024-53986)
Rails.application.config.after_initialize do
  # allowed_tags/allowed_attributes가 nil이면 sanitizer 기본값에서 초기화
  sanitizer_class = ActionText::ContentHelper.sanitizer.class

  ActionText::ContentHelper.allowed_tags ||=
    sanitizer_class.allowed_tags + [ActionText::Attachment.tag_name, "figure", "figcaption"]
  ActionText::ContentHelper.allowed_attributes ||=
    sanitizer_class.allowed_attributes + ActionText::Attachment::ATTRIBUTES

  ActionText::ContentHelper.allowed_tags += %w[table thead tbody tfoot tr th td colgroup col caption u]
  ActionText::ContentHelper.allowed_attributes += ["style", "colspan", "rowspan", "scope"]
end
