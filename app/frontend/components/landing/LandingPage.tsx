import { useState, useEffect } from "react"
import HeroSection, { LandingSection } from "./HeroSection"
import FeaturesSection from "./FeaturesSection"
import TestimonialsSection from "./TestimonialsSection"
import StatsSection from "./StatsSection"
import CtaSection from "./CtaSection"

// 섹션 타입별 컴포넌트 맵
const SECTION_COMPONENTS: Record<string, React.ComponentType<{ section: LandingSection }>> = {
  hero: HeroSection,
  features: FeaturesSection,
  testimonials: TestimonialsSection,
  stats: StatsSection,
  cta: CtaSection,
}

// 섹션이 없을 때 표시되는 기본 히어로 — 잉크 히어로 재사용
function DefaultHero() {
  return (
    <HeroSection
      section={{
        id: 0,
        section_type: "hero",
        title: "바이브코딩으로\n사업을 만드는 사람들",
        subtitle: "코딩 없이 시작하는 1인 사업화 여정을 기록하고, 공유하고, 함께 성장하세요.",
        background_color: null,
        text_color: null,
        position: 0,
        section_cards: [],
      }}
    />
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

  // CLS 방지: 로딩 중에는 잉크 플레이스홀더(네비 라이트 유지 + 깜빡임 방지)
  if (loading) {
    return <div className="tv-ink -mt-[86px] min-h-screen" />
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
