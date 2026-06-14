import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

// 후기 — 잉크 배경 에디토리얼 인용 카드 (서리프 인용부호)
export default function TestimonialsSection({ section }: { section: LandingSection }) {
  const cards = [...section.section_cards].sort((a, b) => a.position - b.position)

  return (
    <FadeInSection>
      <section className="tv-ink relative py-24 px-5">
        <div className="max-w-[1120px] mx-auto relative">
          <p className="tv-eyebrow tv-eyebrow--gold mb-5">Testimonials</p>
          <h2 className="tv-title mb-14">{section.title}</h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {cards.map((card) => (
              <FadeInSection key={card.position}>
                <div
                  className="rounded-card p-7 h-full border"
                  style={{ background: "rgba(255,255,255,0.04)", borderColor: "rgba(241,237,228,0.12)" }}
                >
                  <span className="font-serif italic text-tv-gold block" style={{ fontSize: 48, lineHeight: 0.5, height: 28 }} aria-hidden="true">&ldquo;</span>
                  <p className="text-[15px] leading-relaxed mb-6 text-tv-cream/80">{card.description}</p>
                  <div className="pt-4 border-t" style={{ borderColor: "rgba(241,237,228,0.1)" }}>
                    <p className="font-bold text-tv-cream">{card.title}</p>
                    {card.link_text && <p className="font-mono text-[11px] tracking-wide uppercase text-tv-cream/45 mt-1">{card.link_text}</p>}
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
