# 관리자 계정
admin = User.find_or_create_by!(email_address: "admin@teovibe.com") do |u|
  u.nickname = "관리자"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :admin
end
puts "관리자 계정 생성: admin@teovibe.com / password123"

# 랜딩 페이지 섹션
sections = [
  {
    section_type: :hero,
    title: "바이브코딩으로\n사업을 만드는 사람들",
    subtitle: "코딩 없이 시작하는 1인 사업화 여정을 기록하고, 공유하고, 함께 성장하세요.",
    position: 0,
    cards: []
  },
  {
    section_type: :features,
    title: "TeoVibe에서는\n무엇을 하나요?",
    position: 1,
    cards: [
      { title: "하나, 경험을 기록해요", description: "바이브코딩으로 서비스를 만들며 겪는 시행착오와 인사이트를 블로그에 기록합니다.", icon: "1", position: 0 },
      { title: "둘, 함께 배워요", description: "튜토리얼과 Q&A를 통해 바이브코딩 노하우를 공유하고, 서로의 질문에 답합니다.", icon: "2", position: 1 },
      { title: "셋, 사업화를 실천해요", description: "포트폴리오를 공유하고, 실제 수익을 만드는 과정을 커뮤니티와 함께합니다.", icon: "3", position: 2 }
    ]
  },
  {
    section_type: :stats,
    title: "바이브코딩으로\n함께 만들어가는 이야기",
    position: 2,
    cards: [
      { title: "기록하고", icon: "100+", description: "블로그 글", position: 0 },
      { title: "배우고", icon: "50+", description: "튜토리얼", position: 1 },
      { title: "성장해요", icon: "1,000+", description: "커뮤니티 멤버", position: 2 }
    ]
  },
  {
    section_type: :testimonials,
    title: "다양한 분야에서 바이브코딩으로\n사업을 시작한 멤버들의 이야기",
    position: 3,
    cards: [
      { title: "김민수", description: "비개발자인데 AI 도구만으로 SaaS를 만들어 월 100만원 수익을 올리고 있어요. TeoVibe에서 배운 노하우가 큰 도움이 됐습니다.", link_text: "1인 SaaS 창업자", position: 0 },
      { title: "이서연", description: "프리랜서 디자이너로 일하다 바이브코딩을 배워 자동화 툴을 만들었어요. 클라이언트 관리가 훨씬 수월해졌습니다.", link_text: "프리랜서 디자이너", position: 1 },
      { title: "박준혁", description: "커뮤니티에서 만난 분들과 함께 사이드 프로젝트를 진행하며 실전 경험을 쌓고 있어요. 혼자였으면 포기했을 거예요.", link_text: "마케터 출신 창업자", position: 2 }
    ]
  },
  {
    section_type: :faq,
    title: "자주 묻는 질문",
    position: 4,
    cards: [
      { title: "바이브코딩이 뭔가요?", description: "바이브코딩은 AI 도구(ChatGPT, Claude, Cursor 등)를 활용해 코딩 지식 없이도 실제 동작하는 웹 서비스를 만드는 방법론입니다.", position: 0 },
      { title: "프로그래밍을 전혀 모르는데 가능한가요?", description: "네, 가능합니다. TeoVibe의 튜토리얼은 비개발자를 위해 설계되었으며, 커뮤니티에서 질문하면 경험자들이 도와줍니다.", position: 1 },
      { title: "어떤 도구를 사용하나요?", description: "Claude, ChatGPT 같은 AI 코딩 도구와 Cursor, Windsurf 같은 AI IDE를 주로 사용합니다. 무료로 시작할 수 있습니다.", position: 2 },
      { title: "실제로 수익을 낼 수 있나요?", description: "네, 커뮤니티 멤버 중 바이브코딩으로 SaaS, 자동화 툴, 웹사이트 제작 서비스 등을 통해 수익을 내는 분들이 있습니다.", position: 3 }
    ]
  },
  {
    section_type: :cta,
    title: "TeoVibe와 함께\n바이브코딩 여정을 시작하세요",
    subtitle: "지금 가입하고 바이브코딩 커뮤니티에 참여하세요.",
    position: 5,
    cards: []
  }
]

sections.each do |section_data|
  cards_data = section_data.delete(:cards)
  section = LandingSection.find_or_create_by!(section_type: section_data[:section_type]) do |s|
    s.assign_attributes(section_data)
  end

  cards_data.each do |card_data|
    section.section_cards.find_or_create_by!(title: card_data[:title]) do |c|
      c.assign_attributes(card_data)
    end
  end
end

puts "랜딩 페이지 #{LandingSection.count}개 섹션 생성 완료"
