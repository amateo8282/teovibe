# 강의 카드 (edu 갤러리 디자인 이식). 컬렉션 렌더링: render DeckCardComponent.with_collection(@courses)
class DeckCardComponent < ApplicationComponent
  with_collection_parameter :course

  attr_reader :course

  def initialize(course:, course_counter: 0)
    @course = course
    @i = course_counter
  end

  # 유료 + (미로그인 또는 미구매) = 잠김
  def locked?
    course.paid? && !helpers.current_user&.entitled_to?(course)
  end

  def card_no
    format("%02d", @i + 1)
  end

  # 썸네일 미니 진행바 길이 — 카드마다 다르게
  def progress
    18 + (@i * 17) % 58
  end

  def price_label
    "₩#{helpers.number_with_delimiter(course.price)}"
  end
end
