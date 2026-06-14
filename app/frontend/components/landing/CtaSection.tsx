import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

const Arrow = () => (
  <svg width="15" height="15" viewBox="0 0 16 16" fill="none" aria-hidden="true">
    <path d="M2 8h11M9 3.5 13.5 8 9 12.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
)

// 마무리 CTA — 잉크 밴드 + 골드 헤어라인 + 서리프 강조 + 골드 버튼
export default function CtaSection({ section }: { section: LandingSection }) {
  return (
    <FadeInSection>
      <section className="tv-ink relative py-28 px-5 text-center">
        <span className="absolute top-0 inset-x-0 h-px" aria-hidden="true" style={{ background: "linear-gradient(90deg,transparent,rgba(244,186,84,.5),transparent)" }} />
        <div className="tv-glow tv-glow--gold" aria-hidden="true" style={{ right: "auto", left: "50%", top: "-220px", transform: "translateX(-50%)" }} />
        <div className="tv-ghost" aria-hidden="true" style={{ left: "50%", top: "30%", transform: "translate(-50%,-50%) rotate(-5deg)", fontSize: "clamp(120px,20vw,300px)" }}>
          Start
        </div>

        <div className="max-w-[760px] mx-auto relative">
          <p className="tv-eyebrow tv-eyebrow--gold mb-6" style={{ display: "inline-flex" }}>지금 시작하세요</p>
          <h2 className="font-black leading-[1.06] tracking-[-0.04em] mb-6" style={{ fontSize: "clamp(34px,5.4vw,64px)" }}>
            {section.title}
            <span className="font-serif italic font-normal text-tv-gold">.</span>
          </h2>
          {section.subtitle && <p className="text-lg mb-10 text-tv-cream/65 leading-relaxed">{section.subtitle}</p>}
          <div className="flex flex-wrap gap-3 justify-center">
            <a href="/registration/new" className="tv-btn tv-btn--gold">시작하기 <Arrow /></a>
            <a href="/posts/blog" className="tv-btn tv-btn--ghost">둘러보기</a>
          </div>
        </div>
      </section>
    </FadeInSection>
  )
}
