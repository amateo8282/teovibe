# 재사용 가능한 카드 UI 컴포넌트
class CardComponent < ApplicationComponent
  def initialize(title:, body: nil)
    @title = title
    @body = body
  end
end
