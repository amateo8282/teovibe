import { LandingSection } from "./HeroSection"
import FadeInSection from "./FadeInSection"

// CTA 마무리 섹션: 오렌지 배경 (_cta.html.erb 포팅)
interface CtaSectionProps {
  section: LandingSection
}

export default function CtaSection({ section }: CtaSectionProps) {
  return (
    <FadeInSection>
      <section className="py-24 px-5 bg-tv-orange text-white">
        <div className="max-w-[800px] mx-auto text-center">
          <h2
            className="text-subheading md:text-display font-black leading-tight mb-8"
            style={{ letterSpacing: "-0.8px" }}
          >
            {section.title}
          </h2>
          {section.subtitle && (
            <p className="text-lg mb-10 opacity-90">{section.subtitle}</p>
          )}
          <a
            href="/registrations/new"
            className="inline-block bg-white text-tv-orange rounded-pill px-10 py-4 text-lg font-bold hover:opacity-90 transition-opacity"
          >
            시작하기
          </a>
        </div>
      </section>
    </FadeInSection>
  )
}
