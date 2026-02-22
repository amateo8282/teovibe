import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

// 기능 소개 섹션: 3단 카드 레이아웃 (_features.html.erb 포팅)
interface FeaturesSectionProps {
  section: LandingSection
}

export default function FeaturesSection({ section }: FeaturesSectionProps) {
  // section_cards를 position 순 정렬
  const sortedCards = [...section.section_cards].sort((a, b) => a.position - b.position)

  return (
    <FadeInSection>
      <section className="py-24 px-5">
        <div className="max-w-[1200px] mx-auto">
          {/* 섹션 라벨 */}
          <span className="text-xs font-bold tracking-[0.2em] text-tv-gray uppercase mb-4 block">
            WHAT&apos;S TEOVIBE
          </span>
          <h2
            className="text-subheading md:text-display font-black leading-tight mb-16"
            style={{ letterSpacing: "-0.8px" }}
          >
            {section.title}
          </h2>

          {/* 카드 그리드: 모바일 1열, 데스크톱 3열 */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {sortedCards.map((card) => (
              <FadeInSection key={card.position}>
                <div className="bg-white rounded-card p-8">
                  {card.icon && (
                    <div className="text-4xl mb-4">{card.icon}</div>
                  )}
                  <h3 className="text-subheading font-extrabold mb-3">{card.title}</h3>
                  <p className="text-base text-tv-gray leading-relaxed">{card.description}</p>
                </div>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>
    </FadeInSection>
  )
}
