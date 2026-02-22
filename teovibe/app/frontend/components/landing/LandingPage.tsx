import { useState, useEffect } from "react"
import HeroSection, { LandingSection } from "./HeroSection"

// 섹션 타입별 컴포넌트 맵 (Plan 02에서 추가 섹션 등록)
const SECTION_COMPONENTS: Record<string, React.ComponentType<{ section: LandingSection }>> = {
  hero: HeroSection,
}

// 섹션이 없을 때 표시되는 기본 히어로 (기존 home.html.erb fallback 포팅)
function DefaultHero() {
  return (
    <section className="min-h-[calc(100vh-86px)] flex items-center justify-center bg-tv-cream">
      <div className="text-center max-w-4xl mx-auto px-5">
        <h1 className="text-display md:text-hero font-black tracking-tight leading-tight mb-6">
          바이브코딩으로<br />사업을 만드는 사람들
        </h1>
        <p className="text-lg text-tv-gray mb-10 max-w-xl mx-auto">
          코딩 없이 시작하는 1인 사업화 여정을 기록하고, 공유하고, 함께 성장하세요.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <a
            href="/registrations/new"
            className="bg-tv-black text-white rounded-pill px-8 py-4 text-lg font-bold hover:opacity-90 transition-opacity"
          >
            시작하기
          </a>
          <a
            href="/about"
            className="border border-tv-black text-tv-black rounded-pill px-8 py-4 text-lg font-bold hover:bg-tv-black hover:text-white transition-colors"
          >
            더 알아보기
          </a>
        </div>
      </div>
    </section>
  )
}

export default function LandingPage() {
  const [sections, setSections] = useState<LandingSection[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // API에서 활성화된 랜딩 섹션 목록 조회
    fetch("/api/v1/landing_sections")
      .then((res) => res.json())
      .then((data: LandingSection[]) => {
        setSections(data)
        setLoading(false)
      })
      .catch(() => {
        // 오류 시 빈 배열로 처리 (DefaultHero 표시)
        setSections([])
        setLoading(false)
      })
  }, [])

  // CLS 방지: 로딩 중에는 동일한 높이의 플레이스홀더 유지
  if (loading) {
    return <div className="min-h-[744px] bg-tv-cream" />
  }

  // 섹션이 없으면 기본 히어로 표시
  if (sections.length === 0) {
    return <DefaultHero />
  }

  return (
    <>
      {sections.map((section) => {
        const Component = SECTION_COMPONENTS[section.section_type]
        // 알 수 없는 section_type은 렌더링 스킵
        if (!Component) return null
        return <Component key={section.id} section={section} />
      })}
    </>
  )
}
