import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

// 후기 섹션: 어두운 배경 3단 카드 (_testimonials.html.erb 포팅)
interface TestimonialsSectionProps {
  section: LandingSection
}

export default function TestimonialsSection({ section }: TestimonialsSectionProps) {
  // section_cards를 position 순 정렬
  const sortedCards = [...section.section_cards].sort((a, b) => a.position - b.position)

  return (
    <FadeInSection>
      <section className="py-24 px-5 bg-tv-black text-white">
        <div className="max-w-[1200px] mx-auto">
          {/* 섹션 라벨 */}
          <span className="text-xs font-bold tracking-[0.2em] text-tv-gray uppercase mb-4 block">
            TESTIMONIALS
          </span>
          <h2
            className="text-subheading md:text-display font-black leading-tight mb-16"
            style={{ letterSpacing: "-0.8px" }}
          >
            {section.title}
          </h2>

          {/* 후기 카드 그리드: 모바일 1열, 데스크톱 3열 */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {sortedCards.map((card) => (
              <FadeInSection key={card.position}>
                <div className="bg-tv-dark rounded-card p-8">
                  <p className="text-base leading-relaxed mb-6 text-tv-light-gray">
                    {card.description}
                  </p>
                  <div>
                    <p className="font-bold">{card.title}</p>
                    {card.link_text && (
                      <p className="text-sm text-tv-light-gray">{card.link_text}</p>
                    )}
                  </div>
                </div>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>
    </FadeInSection>
  )
}
