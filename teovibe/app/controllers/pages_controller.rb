class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    @sections = LandingSection.active.ordered.includes(:section_cards)

    # 홈페이지 메타태그 설정
    set_meta_tags(
      description: "AI와 함께 만드는 바이브코딩 커뮤니티",
      og: {
        title: "TeoVibe - 바이브코딩 커뮤니티",
        description: "AI와 함께 만드는 바이브코딩 커뮤니티",
        url: root_url,
        image: "#{request.base_url}/icon.png",
        type: "website"
      }
    )
  end

  def about
  end

  def consulting
  end
end
