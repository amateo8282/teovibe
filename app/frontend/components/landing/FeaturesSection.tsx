import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

// 기능 소개 — 에디토리얼 카드(모노 인덱스 + 아이콘 + 서리프 강조 제목)
export default function FeaturesSection({ section }: { section: LandingSection }) {
  const cards = [...section.section_cards].sort((a, b) => a.position - b.position)
  const titleLines = (section.title || "").split("\n")

  return (
    <FadeInSection>
      <section className="py-24 px-5">
        <div className="max-w-[1120px] mx-auto">
          <p className="tv-eyebrow mb-5">What&apos;s TeoVibe</p>
          <h2 className="tv-title mb-14">
            {titleLines.map((l, i) => (
              <span key={i} className="block">{l}</span>
            ))}
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {cards.map((card, i) => (
              <FadeInSection key={card.position}>
                <div className="tv-card !block p-7 h-full">
                  <div className="flex items-center justify-between mb-5">
                    <span className="font-serif italic text-tv-light-gray" style={{ fontSize: 34, lineHeight: 1 }}>
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    {card.icon && <span className="text-3xl">{card.icon}</span>}
                  </div>
                  <h3 className="text-xl font-black tracking-tight mb-3">{card.title}</h3>
                  <p className="text-[15px] text-tv-gray leading-relaxed">{card.description}</p>
                </div>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>
    </FadeInSection>
  )
}
