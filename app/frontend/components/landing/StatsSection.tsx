import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

// 통계 — 잉크 밴드 + 모노 큰 숫자 + 골드 강조
export default function StatsSection({ section }: { section: LandingSection }) {
  const cards = [...section.section_cards].sort((a, b) => a.position - b.position)

  return (
    <FadeInSection>
      <section className="tv-ink relative py-24 px-5">
        <div className="tv-glow tv-glow--gold" aria-hidden="true" style={{ right: "auto", left: "50%", top: "-200px", transform: "translateX(-50%)" }} />
        <div className="max-w-[1120px] mx-auto relative text-center">
          <p className="tv-eyebrow tv-eyebrow--gold justify-center mb-5" style={{ display: "inline-flex" }}>By the numbers</p>
          <h2 className="tv-title mb-16">{section.title}</h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-y-12 gap-x-8">
            {cards.map((card) => (
              <FadeInSection key={card.position}>
                <div className="flex flex-col items-center gap-3">
                  <span className="font-mono font-semibold text-tv-gold-bright tabular-nums" style={{ fontSize: "clamp(40px,6vw,68px)", lineHeight: 1, letterSpacing: "-1px" }}>
                    {card.icon || card.title}
                  </span>
                  {card.icon && <span className="text-lg font-black tracking-tight text-tv-cream">{card.title}</span>}
                  <span className="font-mono text-[11px] tracking-[2px] uppercase text-tv-cream/45">{card.description}</span>
                </div>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>
    </FadeInSection>
  )
}
