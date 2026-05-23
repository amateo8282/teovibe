import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

// 통계 숫자 섹션: 큰 숫자와 설명 카드 (_stats.html.erb 포팅)
interface StatsSectionProps {
  section: LandingSection
}

export default function StatsSection({ section }: StatsSectionProps) {
  // section_cards를 position 순 정렬
  const sortedCards = [...section.section_cards].sort((a, b) => a.position - b.position)

  return (
    <FadeInSection>
      <section className="py-24 px-5">
        <div className="max-w-[1200px] mx-auto text-center">
          <h2
            className="text-subheading md:text-display font-black leading-tight mb-16"
            style={{ letterSpacing: "-0.8px" }}
          >
            {section.title}
          </h2>

          {/* 통계 카드 그리드: 모바일 1열, 데스크톱 3열 */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {sortedCards.map((card) => (
              <FadeInSection key={card.position}>
                <div className="bg-white rounded-card p-8">
                  {card.icon && (
                    <p className="text-5xl font-black mb-2">{card.icon}</p>
                  )}
                  <h3 className="text-2xl font-extrabold mb-2">{card.title}</h3>
                  <p className="text-tv-gray">{card.description}</p>
                </div>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>
    </FadeInSection>
  )
}
