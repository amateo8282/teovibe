# Phase 3: Interactive Landing - Research

**Researched:** 2026-02-22
**Domain:** React 랜딩페이지 컴포넌트 구현, JSON API 연동, 모바일 반응형, Turbo 언마운트
**Confidence:** HIGH (패턴 확립됨 — Phase 1 결정사항이 상세히 문서화됨), MEDIUM (motion 라이브러리 통합)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LAND-01 | React 컴포넌트로 인터랙티브 랜딩페이지를 구현한다 (애니메이션 히어로, CTA, 소셜프루프 섹션) | motion/react 라이브러리로 entrance + scroll 애니메이션 구현 패턴. 기존 `react-demo.jsx` 마운트 패턴 그대로 확장. |
| LAND-02 | Admin에서 랜딩페이지 섹션 콘텐츠를 관리하면 React 컴포넌트에 반영된다 | Rails API 엔드포인트(`/api/v1/landing_sections`) → React fetch 패턴. LandingSection + SectionCard 모델 이미 존재. |
| LAND-03 | 랜딩페이지가 모바일에서도 매끄럽게 동작한다 (반응형) | Tailwind v4 반응형 prefix(md:, sm:) + 기존 디자인 토큰 사용. 375px 기준 검증. |
</phase_requirements>

---

## Summary

Phase 3는 기존 ERB 기반 랜딩페이지를 React 인터랙티브 컴포넌트로 교체하는 작업이다. **핵심 발견은 대부분의 인프라가 이미 완성되어 있다는 것이다.** LandingSection + SectionCard 모델, Admin CMS, 다수의 ERB 섹션 파셜이 모두 존재한다. Phase 1에서 확립한 React 마운트 패턴(`react-demo.jsx` + `turbo:load`/`turbo:before-cache`)이 그대로 적용된다.

핵심 구현 작업은 세 가지다: (1) 홈페이지를 React 컴포넌트로 교체 — 기존 ERB 섹션 파셜을 React 컴포넌트로 포팅, (2) Rails API 엔드포인트를 추가하여 React가 `fetch`로 섹션 데이터를 가져오도록 연결, (3) `motion/react` 라이브러리로 히어로 입장 애니메이션과 스크롤 트리거 섹션 애니메이션 추가.

Tailwind CSS v4 클래스와 기존 디자인 토큰(`tv-black`, `tv-cream`, `tv-orange` 등)을 React 컴포넌트에서 그대로 사용할 수 있다 — Vite가 전역으로 `application.css`를 처리하기 때문이다. 모바일 반응형은 기존 ERB 섹션이 이미 md: prefix를 사용하고 있으므로, React 포팅 시 동일 패턴을 유지하면 된다.

**Primary recommendation:** 새 진입점 `app/frontend/entrypoints/landing.jsx` + `LandingPage.tsx` 컴포넌트를 만들어 `pages/home.html.erb`에 마운트. Rails에 `/api/v1/landing_sections` 엔드포인트를 추가하여 JSON으로 섹션 데이터를 서빙. `motion/react`로 히어로 stagger 및 `whileInView` 스크롤 애니메이션 구현.

---

## 현재 프로젝트 상태 분석

Phase 3 구현 전 파악해야 할 기존 코드 현황:

### 이미 완성된 것들

| 항목 | 위치 | 상태 |
|------|------|------|
| LandingSection 모델 | `app/models/landing_section.rb` | section_type enum (hero/features/testimonials/stats/pricing/faq/cta/custom), active/ordered scope |
| SectionCard 모델 | DB schema 확인 — title/description/icon/link_url/link_text/position | 완성 |
| Admin CMS | `admin/landing_sections_controller.rb` + `admin/section_cards_controller.rb` | CRUD + move_up/move_down + toggle_active 완성 |
| ERB 섹션 파셜 | `app/views/pages/sections/_hero.html.erb` 등 8종 | 완성 — React 포팅 시 참조 |
| React 마운트 패턴 | `app/frontend/entrypoints/react-demo.jsx` | turbo:load + turbo:before-cache 패턴 확립 |
| Vite 빌드 | `vite.config.ts`, package.json | react + react-dom 19.x 설치됨 |
| 디자인 토큰 | `app/frontend/entrypoints/application.css` `@theme {}` | tv-black, tv-cream, tv-orange 등 전체 토큰 정의됨 |
| scroll-animation | `app/frontend/controllers/scroll_animation_controller.js` | Stimulus IntersectionObserver 기반 — React에서는 motion/react로 대체 |

### 주의: 현재 홈페이지 구조

`app/views/pages/home.html.erb`는 `@sections = LandingSection.active.ordered.includes(:section_cards)`를 받아 ERB 파셜로 렌더링한다. React 전환 시 이 ERB 뷰를 React 마운트 포인트로 바꾸고, 섹션 데이터는 JSON API로 제공해야 한다.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| react | ^19.2.4 (설치됨) | React UI | 이미 설치됨 |
| react-dom | ^19.2.4 (설치됨) | createRoot 마운트 | 이미 설치됨 |
| motion/react | ^11.x (신규 설치) | 입장 애니메이션, 스크롤 트리거 | Framer Motion 후속. High reputation Context7 문서. `motion.div`, `whileInView`, stagger 지원 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| tailwindcss (기존) | ^4.2.0 | 반응형 레이아웃, 디자인 토큰 | React 컴포넌트에서 className으로 직접 사용 |
| 기존 Stimulus scroll-animation | - | 스크롤 애니메이션 (ERB 섹션용) | React 외 ERB 섹션에서 유지. React 내부에서는 motion/react 사용 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| motion/react | CSS transitions only | CSS만으로도 fade-in 가능하나, stagger/spring 등 복잡한 조합은 직접 구현 비용이 높음 |
| motion/react | @react-spring/web | react-spring은 물리 기반이라 자연스럽지만 API가 복잡함. motion이 선언형으로 더 단순 |
| motion/react | 기존 Stimulus scroll-animation-controller | Stimulus는 ERB DOM 조작용. React 내부는 motion으로 분리가 맞음 |
| JSON API fetch | data-* props via ERB | Phase 1 결정: ERB data-* props 방식 금지. JSON API fetch 방식으로 고정 |

**Installation:**
```bash
pnpm add motion
```

주의: 패키지 이름은 `motion` (구 `framer-motion`에서 리브랜딩). import는 `from "motion/react"`.

---

## Architecture Patterns

### Recommended Project Structure

```
app/
├── frontend/
│   ├── entrypoints/
│   │   ├── application.js        # 기존 (변경 없음)
│   │   ├── react-demo.jsx        # 기존 (변경 없음)
│   │   └── landing.jsx           # 신규 — 홈페이지 React 진입점
│   └── components/
│       ├── ReactDemo.tsx          # 기존 (변경 없음)
│       └── landing/               # 신규 — 랜딩페이지 컴포넌트
│           ├── LandingPage.tsx    # 루트 컨테이너 (fetch + 섹션 렌더링)
│           ├── HeroSection.tsx    # 히어로 (애니메이션 핵심)
│           ├── FeaturesSection.tsx
│           ├── TestimonialsSection.tsx
│           ├── StatsSection.tsx
│           ├── CtaSection.tsx
│           └── SectionCard.tsx    # 재사용 카드
app/
├── controllers/
│   └── api/
│       └── v1/
│           └── landing_sections_controller.rb  # 신규 JSON API
├── views/
│   └── pages/
│       └── home.html.erb         # 변경 — React 마운트 포인트로 교체
config/
└── routes.rb                      # 신규 API 라우트 추가
```

### Pattern 1: 랜딩페이지 React 마운트 (Phase 1 패턴 재사용)

**What:** `react-demo.jsx`와 동일한 turbo:load + turbo:before-cache 패턴
**When to use:** `app/frontend/entrypoints/landing.jsx`

```jsx
// app/frontend/entrypoints/landing.jsx
import { createRoot } from "react-dom/client"
import LandingPage from "../components/landing/LandingPage"

let root = null

document.addEventListener("turbo:load", () => {
  const el = document.getElementById("landing-root")
  if (el && !root) {
    root = createRoot(el)
    root.render(<LandingPage />)
  }
})

document.addEventListener("turbo:before-cache", () => {
  if (root) {
    root.unmount()
    root = null
  }
})
```

```erb
<%# app/views/pages/home.html.erb (교체 후) %>
<div id="landing-root"></div>

<% content_for :head do %>
  <%= vite_javascript_tag 'landing' %>
<% end %>
```

### Pattern 2: JSON API 엔드포인트 (섹션 데이터 서빙)

**What:** Rails API 컨트롤러로 LandingSection + SectionCard를 JSON 직렬화
**When to use:** React가 마운트 후 fetch 호출

```ruby
# config/routes.rb 추가
namespace :api do
  namespace :v1 do
    resources :landing_sections, only: [:index]
  end
end
```

```ruby
# app/controllers/api/v1/landing_sections_controller.rb
module Api
  module V1
    class LandingSectionsController < ApplicationController
      allow_unauthenticated_access

      def index
        sections = LandingSection.active.ordered.includes(:section_cards)
        render json: sections.as_json(
          include: { section_cards: { only: [:title, :description, :icon, :link_url, :link_text, :position] } },
          only: [:id, :section_type, :title, :subtitle, :background_color, :text_color, :position]
        )
      end
    end
  end
end
```

### Pattern 3: LandingPage 루트 컴포넌트 (fetch + 로딩 상태)

**What:** 마운트 후 API fetch, 섹션 타입에 따라 적절한 컴포넌트 렌더링
**When to use:** `LandingPage.tsx`

```tsx
// app/frontend/components/landing/LandingPage.tsx
import { useState, useEffect } from "react"
import HeroSection from "./HeroSection"
import FeaturesSection from "./FeaturesSection"
import TestimonialsSection from "./TestimonialsSection"
import CtaSection from "./CtaSection"
import StatsSection from "./StatsSection"

interface SectionCard {
  title: string
  description: string
  icon: string
  link_url: string
  link_text: string
  position: number
}

interface LandingSection {
  id: number
  section_type: string
  title: string
  subtitle: string
  background_color: string | null
  text_color: string | null
  section_cards: SectionCard[]
}

const SECTION_COMPONENTS: Record<string, React.ComponentType<{ section: LandingSection }>> = {
  hero: HeroSection,
  features: FeaturesSection,
  testimonials: TestimonialsSection,
  stats: StatsSection,
  cta: CtaSection,
}

export default function LandingPage() {
  const [sections, setSections] = useState<LandingSection[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch("/api/v1/landing_sections")
      .then(res => res.json())
      .then(data => { setSections(data); setLoading(false) })
      .catch(() => setLoading(false))
  }, [])

  // 섹션 없을 때 기본 히어로 (기존 ERB fallback과 동일)
  if (!loading && sections.length === 0) {
    return <DefaultHero />
  }

  return (
    <>
      {sections.map(section => {
        const Component = SECTION_COMPONENTS[section.section_type]
        if (!Component) return null
        return <Component key={section.id} section={section} />
      })}
    </>
  )
}
```

### Pattern 4: motion/react 히어로 입장 애니메이션

**What:** `motion.div`로 히어로 텍스트와 CTA 버튼에 stagger 입장 애니메이션
**Source:** Context7 `/websites/motion_dev` — motion/react whileInView, stagger 패턴

```tsx
// app/frontend/components/landing/HeroSection.tsx
import { motion } from "motion/react"

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.15, delayChildren: 0.1 }
  }
}

const itemVariants = {
  hidden: { opacity: 0, y: 24 },
  show: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.22, 1, 0.36, 1] } }
}

export default function HeroSection({ section }) {
  return (
    <section className="min-h-[744px] flex items-center justify-center bg-tv-cream relative overflow-hidden">
      <motion.div
        className="text-center max-w-5xl mx-auto px-5 relative z-10"
        variants={containerVariants}
        initial="hidden"
        animate="show"
      >
        <motion.h1
          className="text-display md:text-hero font-black tracking-tight leading-tight mb-6"
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
          <a href="/registrations/new" className="bg-tv-black text-white rounded-pill px-7 py-4 text-lg font-bold hover:opacity-90 transition-opacity">
            시작하기 →
          </a>
          <a href="/about" className="border border-tv-black text-tv-black rounded-pill px-7 py-4 text-lg font-bold hover:bg-tv-black hover:text-white transition-colors">
            더 알아보기
          </a>
        </motion.div>
      </motion.div>
    </section>
  )
}
```

### Pattern 5: whileInView 스크롤 트리거 (하위 섹션 공통 패턴)

**What:** 스크롤 시 섹션이 뷰포트에 들어올 때 fade-in
**Source:** Context7 `/websites/motion_dev` — whileInView + viewport.once

```tsx
// 재사용 가능한 스크롤 입장 래퍼
import { motion } from "motion/react"

function FadeInSection({ children, className }) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 32 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.1 }}
      transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  )
}
```

### Anti-Patterns to Avoid

- **ERB 링크 헬퍼(`link_to`) React에서 사용:** React 컴포넌트는 Ruby ERB가 아니므로 `link_to` 사용 불가. 일반 `<a href>` 태그 또는 Rails 경로를 하드코딩하여 사용. (경로는 변경 빈도 낮으므로 수용 가능)
- **`motion` 패키지를 `framer-motion`으로 import:** 패키지명이 변경됨. `import { motion } from "framer-motion"` 아닌 `import { motion } from "motion/react"` 사용
- **React 컴포넌트 내에서 Tailwind CSS 클래스 인라인 스타일로 대체:** `application.css`의 `@theme` 블록이 전역으로 로드되므로, className에 `bg-tv-cream` 등 커스텀 토큰 클래스 직접 사용 가능. 인라인 스타일 불필요
- **랜딩 섹션 데이터를 ERB data-* props로 전달:** Phase 1 결정 위반. JSON API fetch 방식 준수
- **중복 마운트:** `turbo:load`에서 `if (el && !root)` 가드 없이 createRoot 호출 — 이미 `react-demo.jsx`에서 해결된 패턴이므로 동일하게 적용

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 스크롤 입장 애니메이션 | IntersectionObserver 직접 구현 | `motion/react` whileInView | 이미 `scroll_animation_controller.js`가 Stimulus용으로 있지만, React 내부는 motion이 훨씬 단순 |
| Spring/Easing 커브 계산 | 직접 CSS cubic-bezier 튜닝 | motion의 `ease: [0.22, 1, 0.36, 1]` | 검증된 iOS-style ease-out 커브, 즉시 사용 가능 |
| 섹션 데이터 캐싱 | 커스텀 캐시 레이어 | React useState + useEffect 단순 fetch | 랜딩페이지는 자주 바뀌지 않고, 마운트당 1회 fetch면 충분 |
| 라우팅 | React Router | 없음 — 단일 페이지 내 섹션 렌더링 | Phase 3는 홈페이지 단일 URL. 내부 섹션 간 라우팅 불필요 |

**Key insight:** 기존 Stimulus `scroll_animation_controller.js`는 ERB DOM용이고 React 컴포넌트 내부에서는 접근 불가. React 내에서는 `motion/react`의 `whileInView`가 동일한 IntersectionObserver 역할을 한다.

---

## Common Pitfalls

### Pitfall 1: 홈페이지 교체 시 Turbo Drive 캐시 오염

**What goes wrong:** 기존 ERB 렌더링된 홈페이지를 뒤로가기할 때, Turbo 캐시에 저장된 React 마운트 이전 DOM이 잠깐 보이다가 React가 다시 마운트되는 깜박임 발생.

**Why it happens:** Turbo는 페이지 이탈 직전 DOM을 스냅샷으로 저장한다. `turbo:before-cache`에서 React를 언마운트하면 `#landing-root` 내부가 비어 Turbo 캐시에 빈 div가 저장되고, 뒤로가기 시 빈 상태가 잠깐 표시된다.

**How to avoid:** 이는 React-in-Turbo의 정상 동작이다. 언마운트 시 로딩 스피너나 스켈레톤 HTML을 `#landing-root` 안에 남기는 방법도 있으나, Phase 3에서는 단순하게 빈 div를 허용하는 것이 더 적절하다. 히어로 배경색을 ERB 쪽 div에도 적용해두면 깜박임이 덜 눈에 띈다.

**Warning signs:** 뒤로가기 시 흰 화면이 0.5초 이상 보이는 경우

---

### Pitfall 2: Tailwind CSS 커스텀 토큰 클래스 누락

**What goes wrong:** React 컴포넌트에서 `bg-tv-cream`, `text-tv-black` 등 커스텀 Tailwind 클래스를 사용했는데 스타일이 적용되지 않는다.

**Why it happens:** `application.css`의 `@theme` 블록은 Vite가 빌드할 때 전역으로 처리된다. 그러나 Tailwind v4는 JIT 방식이므로, React TSX/JSX 파일의 className에 사용된 클래스가 Tailwind의 content 스캔 경로에 포함되어야 한다.

**How to avoid:** `vite.config.ts` 또는 `tailwind.config`에서 content 경로에 `app/frontend/**/*.{tsx,jsx,ts,js}` 포함 여부 확인. Tailwind v4에서는 기본적으로 Vite가 처리하는 파일을 자동 감지하지만, 경로 설정 확인이 필요하다.

**Warning signs:** className에 `bg-tv-cream`을 넣었는데 배경색이 없는 경우. 브라우저 DevTools에서 해당 클래스의 CSS 규칙이 없는 경우.

---

### Pitfall 3: API 엔드포인트 인증 미처리

**What goes wrong:** `/api/v1/landing_sections` 엔드포인트에서 `allow_unauthenticated_access` 없이 배포 시, 비로그인 방문자가 랜딩페이지를 열면 API 호출이 401로 실패하여 빈 페이지가 표시된다.

**Why it happens:** Rails 8의 기본 인증 before_action이 ApplicationController에 있을 경우, API 컨트롤러도 상속받아 인증을 요구할 수 있다.

**How to avoid:** `Api::V1::LandingSectionsController`에 `allow_unauthenticated_access`를 명시적으로 추가. `pages#home`과 동일한 처리.

**Warning signs:** 비로그인 상태에서 `/api/v1/landing_sections`를 직접 curl했을 때 302 리다이렉트 또는 401 응답.

---

### Pitfall 4: motion/react 번들 크기 과도 증가

**What goes wrong:** `motion` 전체를 import하면 번들에 불필요한 코드가 포함될 수 있다.

**Why it happens:** motion 패키지는 tree-shakeable하지만, 잘못된 import 방식 시 전체 번들 포함 가능.

**How to avoid:** `import { motion, useInView, AnimatePresence } from "motion/react"` 방식으로 named import 사용. `import motion from "motion"` (default import) 방식 회피. Vite가 자동으로 tree-shake하므로 named import면 충분하다.

---

### Pitfall 5: 로딩 상태 미처리로 레이아웃 점프 (CLS)

**What goes wrong:** React 마운트 후 API fetch 완료 전까지 `#landing-root`가 비어 있어, fetch 완료 후 콘텐츠가 갑자기 나타나며 레이아웃이 점프한다.

**Why it happens:** 비동기 데이터 fetch 전에는 렌더링할 섹션 데이터가 없다.

**How to avoid:** 로딩 중에는 최소한 히어로 섹션 높이만큼의 placeholder를 렌더링한다:
```tsx
if (loading) {
  return <div className="min-h-[744px] bg-tv-cream" />
}
```

---

## Code Examples

Verified patterns from official sources:

### motion/react 기본 import 패턴

```tsx
// Source: motion.dev 공식 문서, Context7 /websites/motion_dev
import { motion } from "motion/react"

// 기본 fade-in + 위에서 아래로 입장
<motion.div
  initial={{ opacity: 0, y: 24 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
>
  {children}
</motion.div>
```

### whileInView 스크롤 트리거

```tsx
// Source: Context7 /websites/motion_dev — whileInView + viewport
<motion.section
  initial={{ opacity: 0, y: 32 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.1 }}
  transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
>
  {/* 섹션 콘텐츠 */}
</motion.section>
```

### Stagger children 애니메이션

```tsx
// Source: Context7 /websites/motion_dev — staggerChildren
const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.12, delayChildren: 0.1 }
  }
}
const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] } }
}

<motion.div variants={containerVariants} initial="hidden" animate="show">
  <motion.h1 variants={itemVariants}>제목</motion.h1>
  <motion.p variants={itemVariants}>부제목</motion.p>
  <motion.div variants={itemVariants}>CTA 버튼</motion.div>
</motion.div>
```

### Rails JSON API (as_json)

```ruby
# Source: Rails guides — as_json with includes
render json: sections.as_json(
  only: [:id, :section_type, :title, :subtitle, :background_color, :text_color, :position],
  include: {
    section_cards: {
      only: [:title, :description, :icon, :link_url, :link_text, :position]
    }
  }
)
```

### Tailwind v4 반응형 (기존 ERB 섹션 패턴 참조)

```tsx
// 기존 ERB 섹션의 반응형 패턴을 React에서 동일하게 사용
// Source: 기존 app/views/pages/sections/_hero.html.erb 참조
<h1 className="text-display md:text-hero font-black tracking-tight leading-tight mb-6">
  {section.title}
</h1>
<div className="grid grid-cols-1 md:grid-cols-3 gap-8">
  {section.section_cards.map(card => (
    <div key={card.position} className="bg-white rounded-card p-8">
      {/* 카드 내용 */}
    </div>
  ))}
</div>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| framer-motion | motion/react | 2024 리브랜딩 | import path 변경: `from "motion/react"` |
| Stimulus IntersectionObserver | motion/react whileInView | Phase 3 결정 | React 컴포넌트 내부만 해당. ERB 섹션은 기존 Stimulus 유지 |
| ERB 파셜 섹션 렌더링 | React 컴포넌트 섹션 렌더링 | Phase 3 | JSON API fetch 연동으로 Admin CMS와 동일한 데이터 사용 |

**Deprecated/outdated:**

- `framer-motion` 패키지명: `motion` 패키지로 리브랜딩. `import { motion } from "framer-motion"` 패턴은 레거시.
- ERB `data-controller="scroll-animation"` 속성: React 컴포넌트 내에서는 효과 없음 (Stimulus는 ERB DOM에만 작동). React 섹션에서는 motion/react의 `whileInView` 사용.

---

## Open Questions

1. **홈페이지 ERB 완전 교체 vs. 하이브리드**
   - What we know: 현재 `home.html.erb`는 ERB 파셜로 섹션을 렌더링한다. React로 교체 시 `#landing-root` 단일 div로 변경.
   - What's unclear: Admin에서 새 section_type을 추가할 때 React 컴포넌트도 함께 추가해야 하는 유지보수 부담이 있다. `custom` 타입의 경우 React에서 어떻게 렌더링할지 결정 필요.
   - Recommendation: `custom` 타입은 단순 텍스트 렌더링 fallback 컴포넌트로 처리. 알 수 없는 section_type은 null 반환(렌더링 스킵).

2. **섹션 없을 때의 Default Hero 처리**
   - What we know: 현재 `home.html.erb`에 `if @sections.empty?` 분기로 기본 히어로 ERB가 있다.
   - What's unclear: React 전환 후 DB에 활성 섹션이 없을 때의 fallback을 React에서도 구현해야 하는지.
   - Recommendation: React `LandingPage.tsx`에서 `sections.length === 0`일 때 하드코딩된 기본 히어로를 렌더링. 기존 ERB fallback과 동일한 내용.

3. **그리드 배경(SVG) 재현**
   - What we know: 기존 `_hero.html.erb`에 인라인 SVG data URI로 그리드 배경이 있다.
   - What's unclear: React의 className과 style prop으로 동일한 배경을 재현 가능한지.
   - Recommendation: `style={{ backgroundImage: "url(data:image/svg+xml,...)" }}`로 인라인 style prop 사용. 동일한 SVG 문자열을 복사하되, React에서는 URL encoding 주의.

---

## Sources

### Primary (HIGH confidence)

- Context7 `/websites/motion_dev` — motion/react whileInView, stagger, variants API
- 로컬 프로젝트 직접 검사 — LandingSection 모델, SectionCard 모델, Admin CMS, ERB 섹션 파셜 8종, package.json(react 19.x 설치 확인)
- Phase 1 RESEARCH.md + 01-03-PLAN.md — React 마운트 패턴(turbo:load + turbo:before-cache) 확정 패턴
- Phase 1 CONTEXT.md — 잠긴 결정사항 (JSON API fetch 방식, Turbo Drive 유지)

### Secondary (MEDIUM confidence)

- Context7 `/websites/motion_dev` — stagger, delayChildren 패턴 (Vue 예시 기반이나 React API 동일)
- motion.dev 공식 문서 추론 — `motion/react` import path (framer-motion에서 리브랜딩)
- Tailwind v4 content 스캔 동작 — vite 플러그인이 자동 감지 처리로 알려져 있으나, 실제 tsx 파일 감지 범위 미검증

### Tertiary (LOW confidence)

- CLS 방지를 위한 placeholder 패턴 — 일반적 React best practice이나 이 프로젝트 맥락에서 직접 검증하지 않음

---

## Metadata

**Confidence breakdown:**
- Standard stack (React 19, motion/react): HIGH — 이미 react/react-dom 설치됨, motion은 공식 문서로 확인
- Architecture (JSON API + 마운트 패턴): HIGH — Phase 1에서 확립된 패턴 재사용
- Animation (motion/react whileInView, stagger): MEDIUM — Context7 문서 기반이나 실제 통합 미검증
- Tailwind 커스텀 토큰 React 적용: MEDIUM — Vite 전역 처리로 동작할 것으로 예상, 실제 빌드 확인 필요
- Pitfalls: MEDIUM — Phase 1 경험 + React-in-Turbo 일반 패턴 기반

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (React/motion 안정적, Rails API 패턴 변경 없음)
