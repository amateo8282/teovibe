# edu 강의 시드 — 무료 4(주차) + 유료 3(심화, 각 ₩990, Polar 프로덕션 매핑)
# 실행: bin/rails runner db/seed_courses.rb
COURSES = [
  { slug: "week-1-2", title: "바이브코딩 마스터 1~2주차", emoji: "🌱",
    deck_file: "vibe-coding-week1-2.html", slides_count: 27, duration: "90분 × 2회",
    tag: "WEEK 1-2", level: "기본", thumb_style: "thumb--dark", position: 1, paid: false, price: 0,
    description: "Claude와 프롬프트로 코딩하는 방법, 개발 환경 셋업, 첫 프로젝트 완성." },
  { slug: "week-3-4", title: "바이브코딩 마스터 3~4주차", emoji: "🔧",
    deck_file: "vibe-coding-week3-4.html", slides_count: 29, duration: "90분 × 2회",
    tag: "WEEK 3-4", level: "기본", thumb_style: "thumb--green", position: 2, paid: false, price: 0,
    description: "컴포넌트 설계와 데이터 흐름. 실전 앱 구조를 잡고 기능을 확장하는 단계." },
  { slug: "week-5-6", title: "바이브코딩 마스터 5~6주차", emoji: "⚡",
    deck_file: "vibe-coding-week5-6.html", slides_count: 28, duration: "90분 × 2회",
    tag: "WEEK 5-6", level: "기본", thumb_style: "thumb--gold", position: 3, paid: false, price: 0,
    description: "API 연동과 외부 서비스 통합. 실제 데이터를 다루고 완성도 있는 서비스 구축." },
  { slug: "week-7-8", title: "엔티티 완전 정복 — 7~8주차", emoji: "🏗️",
    deck_file: "vibe-coding-week7-8.html", slides_count: 32, duration: "120분 × 2회",
    tag: "WEEK 7-8", level: "기본", thumb_style: "thumb--burgundy", position: 4, paid: false, price: 0,
    description: "DB 설계부터 클린 아키텍처, 바이브코딩까지. 코드 품질을 높이고 프로젝트를 완주." },

  { slug: "cicd", title: "CI/CD 완전 정복", emoji: "🚀",
    deck_file: "cicd-education.html", slides_count: 12, duration: "90분",
    tag: "심화", level: "심화", thumb_style: "thumb--orange", position: 5, paid: true, price: 990,
    polar_product_id: "7f21890f-c966-45be-855c-a8b881c3eff2",
    polar_benefit_id: "ef4c6b28-af80-416b-86a4-8fd281cb43a2",
    checkout_url: "https://buy.polar.sh/polar_cl_RnpRy4jwgQrJXIt6fRfMaOtcCtjSawsfNfGNz0OJ9Az",
    description: "GitHub Actions로 배포 자동화. 내 프로젝트에 CI/CD 파이프라인 직접 구축하기." },
  { slug: "agent-sdk", title: "claude -p와 Agent SDK 입문", emoji: "🤖",
    deck_file: "claude-p-agent-sdk.html", slides_count: 15, duration: "90분",
    tag: "심화", level: "심화", thumb_style: "thumb--dark", position: 6, paid: true, price: 990,
    polar_product_id: "1a24590f-d3ed-48dc-8bdb-21a782d25bd9",
    polar_benefit_id: "8cdc545a-4b85-4f23-a24d-540dd74192fc",
    checkout_url: "https://buy.polar.sh/polar_cl_tB6dPAbTqLwLfs4lqIxQz18IBcHQH0Hum0l9N3FKWo8",
    description: "claude -p 플래그와 Agent SDK로 반복 작업을 자동화하는 실전 가이드." },
  { slug: "vertical-agent", title: "스킬에서 버티컬 에이전트까지", emoji: "🧠",
    deck_file: "vertical-agent-curriculum.html", slides_count: 40, duration: "3시간",
    tag: "심화", level: "심화", thumb_style: "thumb--green", position: 7, paid: true, price: 990,
    polar_product_id: "9a45a45d-c837-4ee5-a8e6-9a2a9b185627",
    polar_benefit_id: "4f2c912f-06fa-423e-a362-2b95927b663d",
    checkout_url: "https://buy.polar.sh/polar_cl_T4IuBlBJVF57WeGi3AOLVJNsSBfzpAIwNrTe2045Ggf",
    description: "단일 스킬에서 수익화 파이프라인까지. 버티컬 에이전트 설계와 구현 전 과정." }
].freeze

COURSES.each do |attrs|
  c = Course.find_or_initialize_by(slug: attrs[:slug])
  c.assign_attributes(attrs.merge(status: :published))
  c.save!
  puts "#{c.paid? ? '💰₩' + c.price.to_s : '🆓'}  #{c.title}  (#{c.deck_exists? ? 'deck OK' : 'DECK MISSING'})"
end
puts "총 #{Course.published.count}개 강의 (유료 #{Course.where(paid: true).count})"
