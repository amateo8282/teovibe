import { motion } from "motion/react"

// LandingPage에서 공유하는 타입 (순환 의존 방지를 위해 여기서 재정의)
interface SectionCard {
  title: string
  description: string
  icon: string
  link_url: string
  link_text: string
  position: number
}

export interface LandingSection {
  id: number
  section_type: string
  title: string
  subtitle: string
  background_color: string | null
  text_color: string | null
  position: number
  section_cards: SectionCard[]
}

const container = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.12, delayChildren: 0.05 } },
}
const item = {
  hidden: { opacity: 0, y: 28 },
  show: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.22, 1, 0.36, 1] } },
}

const Arrow = () => (
  <svg width="15" height="15" viewBox="0 0 16 16" fill="none" aria-hidden="true">
    <path d="M2 8h11M9 3.5 13.5 8 9 12.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
)

// 잉크 히어로: 그리드 + 드리프트 글로우 + 서리프 고스트 워드마크 + 스태거 리빌
export default function HeroSection({ section }: { section: LandingSection }) {
  const lines = (section.title || "").split("\n")
  return (
    <section className="tv-ink relative -mt-[86px] flex items-center min-h-[92vh] px-5 pt-[120px] pb-24">
      <div className="tv-ink-grid" aria-hidden="true" />
      <div className="tv-glow tv-glow--gold" aria-hidden="true" />
      <div className="tv-glow tv-glow--green" aria-hidden="true" />
      <div className="tv-ghost" aria-hidden="true" style={{ right: "-2vw", top: "12%", fontSize: "clamp(110px,18vw,260px)", transform: "rotate(-7deg)" }}>
        Vibe!
      </div>

      <motion.div className="max-w-[1120px] mx-auto w-full relative" variants={container} initial="hidden" animate="show">
        <motion.p className="tv-eyebrow tv-eyebrow--gold mb-7" variants={item}>
          <span className="dot" aria-hidden="true" />TeoVibe · 바이브코딩 커뮤니티
        </motion.p>

        <motion.h1 className="font-black leading-[1.04] tracking-[-0.045em] mb-7" style={{ fontSize: "clamp(44px,8.4vw,104px)" }} variants={item}>
          {lines.map((line, i) => (
            <span key={i} className="block">
              {line}
              {i === lines.length - 1 && <span className="font-serif italic font-normal text-tv-gold">*</span>}
            </span>
          ))}
        </motion.h1>

        {section.subtitle && (
          <motion.p className="leading-relaxed text-tv-cream/60 max-w-[540px] mb-9" style={{ fontSize: "clamp(15.5px,1.7vw,18px)" }} variants={item}>
            {section.subtitle}
          </motion.p>
        )}

        <motion.div className="flex flex-wrap gap-3" variants={item}>
          <a href="/registration/new" className="tv-btn tv-btn--gold">시작하기 <Arrow /></a>
          <a href="/about" className="tv-btn tv-btn--ghost">더 알아보기</a>
        </motion.div>
      </motion.div>
    </section>
  )
}
