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

// 그리드 SVG 배경 (기존 _hero.html.erb와 동일한 패턴)
const GRID_BACKGROUND = `url("data:image/svg+xml,%3Csvg width='40' height='40' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M0 0h40v40H0z' fill='none'/%3E%3Cpath d='M0 40V0h1v40zm40 0V0h1v40z' fill='%23ddd6c8' fill-opacity='0.3'/%3E%3Cpath d='M0 0h40v1H0zm0 40h40v1H0z' fill='%23ddd6c8' fill-opacity='0.3'/%3E%3C/svg%3E")`

// stagger 컨테이너 애니메이션 변형
const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.15,
      delayChildren: 0.1,
    },
  },
}

// 개별 아이템 애니메이션 변형
const itemVariants = {
  hidden: { opacity: 0, y: 24 },
  show: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.6,
      ease: [0.22, 1, 0.36, 1],
    },
  },
}

interface HeroSectionProps {
  section: LandingSection
}

export default function HeroSection({ section }: HeroSectionProps) {
  return (
    <section
      className="min-h-[744px] flex items-center justify-center bg-tv-cream relative overflow-hidden"
      style={{ backgroundImage: GRID_BACKGROUND }}
    >
      <motion.div
        className="text-center max-w-5xl mx-auto px-5 relative z-10"
        variants={containerVariants}
        initial="hidden"
        animate="show"
      >
        <motion.h1
          className="text-display md:text-hero font-black tracking-tight leading-tight mb-6"
          style={{ letterSpacing: "-0.8px" }}
          variants={itemVariants}
        >
          {section.title}
        </motion.h1>

        {section.subtitle && (
          <motion.p
            className="text-lg md:text-xl text-tv-gray mb-10 max-w-2xl mx-auto leading-relaxed"
            variants={itemVariants}
          >
            {section.subtitle}
          </motion.p>
        )}

        <motion.div
          className="flex flex-col sm:flex-row gap-4 justify-center"
          variants={itemVariants}
        >
          <a
            href="/registrations/new"
            className="bg-tv-black text-white rounded-pill px-7 py-4 text-lg font-bold hover:opacity-90 transition-opacity"
          >
            시작하기 -&gt;
          </a>
          <a
            href="/about"
            className="border border-tv-black text-tv-black rounded-pill px-7 py-4 text-lg font-bold hover:bg-tv-black hover:text-white transition-colors"
          >
            더 알아보기
          </a>
        </motion.div>
      </motion.div>
    </section>
  )
}
