# Phase 1: Foundation - Research

**Researched:** 2026-02-22
**Domain:** Rails 8.1 JS Build Pipeline (vite_ruby), SQLite WAL + Solid 인프라, ViewComponent
**Confidence:** HIGH (Core stack), MEDIUM (Turbo+React lifecycle), HIGH (SQLite WAL)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- React 마운트 패턴: 전용 페이지 마운트 방식 — 특정 페이지 전체를 React가 담당하는 구조
- ERB 안에 부분 삽입(Island) 방식은 사용하지 않음
- 데이터 전달은 JSON API 호출 방식 — React가 마운트 후 fetch로 Rails API를 호출하여 데이터를 가져옴
- ERB에서 data-* 속성으로 props를 전달하는 방식은 사용하지 않음
- React 전용 페이지도 Turbo Drive 네비게이션을 유지함 (data-turbo=false 사용 안 함)
- React 컴포넌트의 마운트/언마운트 라이프사이클을 Turbo 이벤트에 맞춰 처리해야 함

### Claude's Discretion

- Phase 1에서의 React 확인용 데모 컴포넌트 형태 (마운트 동작 확인이 목적)
- ViewComponent 첫 추출 대상 선정
- ImportMap에서 vite_ruby로의 마이그레이션 세부 전략
- Propshaft와 vite_ruby 공존 방식
- SQLite WAL 모드 및 Solid 인프라 구성 세부사항
- 개발 환경 HMR/빌드 설정

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INFRA-01 | ImportMap에서 vite_ruby로 JavaScript 빌드 파이프라인을 전환하여 JSX/React/npm 패키지를 사용할 수 있다 | vite_ruby 3.9.2 설치 절차, Propshaft 공존 전략, Stimulus glob 마이그레이션, React HMR 설정 |
| INFRA-02 | SQLite WAL 모드를 활성화하고 Solid Queue/Cache/Cable이 별도 DB 파일을 사용하도록 구성한다 | Rails 8.1 WAL 자동 적용 확인(primary DB), 개발 환경 별도 DB 추가 database.yml 패턴, Solid 어댑터 config 활성화 |
| INFRA-03 | ViewComponent gem을 도입하여 재사용 가능한 UI 컴포넌트 구조를 마련한다 | view_component 4.4.0 설치, 제너레이터 사용법, ERB 렌더링, Tailwind CSS v4 클래스 적용 패턴 |
</phase_requirements>

---

## Summary

Phase 1은 세 개의 독립적인 기술 영역으로 구성된다: (1) ImportMap → vite_ruby 빌드 파이프라인 전환, (2) SQLite WAL 모드 + Solid 인프라 개발 환경 별도 DB 구성, (3) ViewComponent 도입. 각 영역은 서로 의존하지 않으므로 순서 자유롭게 진행 가능하나, 01-01(vite_ruby)이 나머지 Phase들의 기반이므로 먼저 완료하는 것이 권장된다.

**가장 복잡한 부분**은 01-01이다. tailwindcss-rails gem이 독립적인 CSS 빌더로 동작하고 있으므로, vite_ruby 추가 시 Tailwind CSS 처리를 Vite(@tailwindcss/vite)로 이전할지 아니면 tailwindcss-rails를 유지할지 결정이 필요하다. 현재 프로젝트는 Tailwind v4 (@theme 블록 방식)를 사용 중이므로 @tailwindcss/vite 플러그인으로 이전하는 방향이 자연스럽다. Propshaft는 tailwindcss-rails 제거 후에는 필요 없으나, 혹시 다른 gem이 의존할 수 있으므로 유지 여부 확인이 필요하다.

**01-02(SQLite WAL)**는 실제로 Rails 8.1 + sqlite3 gem 2.9.0에서 primary DB에는 이미 WAL이 자동 적용되어 있음을 확인했다. 작업의 핵심은 개발 환경에서도 queue/cache/cable 별도 SQLite 파일을 만들고 Solid 어댑터들을 활성화하는 것이다.

**01-03(ViewComponent)**는 가장 단순하다. gem 추가 → 제너레이터로 첫 컴포넌트 생성 → ERB에서 렌더링 확인의 3단계이다.

**Primary recommendation:** vite_ruby 설치 시 tailwindcss-rails gem을 제거하고 @tailwindcss/vite로 일원화한다. Propshaft도 제거한다. importmap-rails gem만 제거하고 layout의 javascript_importmap_tags를 vite 태그로 교체한다.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| vite_rails | 3.0.20 | vite_ruby Rails 통합 gem | vite_ruby(3.9.2)에 의존, Rails 전용 헬퍼 제공 |
| vite_ruby | 3.9.2 | Vite.js Ruby 통합 코어 | 유일한 Rails용 Vite 통합 라이브러리, High reputation |
| @vitejs/plugin-react | latest | React + HMR 지원 | React Fast Refresh 공식 플러그인 |
| @tailwindcss/vite | latest | Tailwind CSS v4 Vite 통합 | Tailwind v4의 공식 Vite 플러그인 방식 |
| stimulus-vite-helpers | latest | Stimulus 컨트롤러 glob 등록 | import.meta.glob 기반 자동 등록 |
| view_component | 4.4.0 | Rails UI 컴포넌트 프레임워크 | 최신 버전, Rails 8 지원 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| vite-plugin-rails | latest | vite_ruby의 npm 측 플러그인 | vite.config.ts에서 Rails 통합 설정 |
| react | latest (^19) | React 라이브러리 | JSX 컴포넌트 작성용 |
| react-dom | latest (^19) | React DOM 렌더러 | createRoot 마운트용 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @tailwindcss/vite | tailwindcss-rails 유지 | tailwindcss-rails 유지 시 별도 watch 프로세스 필요, Vite HMR와 분리됨 |
| vite_ruby | esbuild-rails | esbuild-rails는 JSX를 지원하지만 HMR 없음, 플러그인 생태계 없음 |
| vite_ruby | jsbundling-rails (rollup/webpack) | 더 무겁고 설정 복잡, HMR 품질 낮음 |
| view_component | Phlex | Phlex는 Ruby DSL 방식, ERB 템플릿 없음. 기존 팀 컨벤션과 다름 |

**Installation:**

```bash
# Gemfile에 추가
bundle add vite_rails
bundle add view_component

# vite_ruby 설치 스크립트
bundle exec vite install

# npm 패키지 (pnpm 사용)
pnpm add -D vite @vitejs/plugin-react vite-plugin-rails @tailwindcss/vite stimulus-vite-helpers
pnpm add react react-dom
```

---

## Architecture Patterns

### Recommended Project Structure

```
app/
├── frontend/                    # vite_ruby 기본 sourceCodeDir
│   ├── entrypoints/             # Vite 진입점 (tag helper로 참조되는 파일)
│   │   ├── application.js       # 기존 Stimulus/Turbo 진입점
│   │   └── react-demo.jsx       # Phase 1 React 데모 진입점
│   ├── controllers/             # Stimulus 컨트롤러 (기존 app/javascript/controllers/ 이전)
│   │   ├── index.js
│   │   └── *_controller.js
│   └── components/              # 향후 React 컴포넌트
│       └── ReactDemo.tsx
├── components/                  # ViewComponent (Rails convention)
│   ├── application_component.rb
│   └── card_component.rb
│   └── card_component.html.erb
config/
├── vite.json                    # vite_ruby 설정
vite.config.ts                   # Vite 빌드 설정
package.json                     # npm 의존성 (pnpm 사용)
```

### Pattern 1: vite_ruby Layout 태그 교체

**What:** `javascript_importmap_tags` → vite 태그 헬퍼로 교체
**When to use:** application.html.erb 레이아웃에서

```erb
<%# Before (importmap) %>
<%= javascript_importmap_tags %>

<%# After (vite_ruby) %>
<%= vite_client_tag %>
<%= vite_react_refresh_tag %>
<%= vite_javascript_tag 'application' %>
```

Source: https://vite-ruby.netlify.app/guide/rails.html

### Pattern 2: Stimulus 컨트롤러 glob 등록

**What:** importmap 방식의 `eagerLoadControllersFrom` → `import.meta.glob` 방식으로 전환
**When to use:** `app/frontend/controllers/index.js`

```javascript
// Before (importmap 방식)
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// After (vite_ruby 방식)
import { Application } from "@hotwired/stimulus"
import { registerControllers } from "stimulus-vite-helpers"

const application = Application.start()
const controllers = import.meta.glob("./**/*_controller.js", { eager: true })
registerControllers(application, controllers)
```

Source: https://github.com/ElMassimo/stimulus-vite-helpers

### Pattern 3: React 전용 페이지 마운트 (Turbo 지원)

**What:** Turbo Drive 네비게이션 유지하면서 React 컴포넌트 마운트/언마운트
**When to use:** React 전용 페이지 진입점 파일

```jsx
// app/frontend/entrypoints/react-page.jsx
import { createRoot } from "react-dom/client"
import ReactDemo from "../components/ReactDemo"

let root = null

// Turbo Drive 페이지 진입 시 마운트
document.addEventListener("turbo:load", () => {
  const el = document.getElementById("react-root")
  if (el && !root) {
    root = createRoot(el)
    root.render(<ReactDemo />)
  }
})

// Turbo Drive 페이지 이탈 전 언마운트 (캐시 오염 방지)
document.addEventListener("turbo:before-cache", () => {
  if (root) {
    root.unmount()
    root = null
  }
})
```

**ERB 레이아웃에서 특정 페이지에만 로드:**

```erb
<%# app/views/demo/react.html.erb %>
<div id="react-root"></div>
<% content_for :head do %>
  <%= vite_javascript_tag 'react-page' %>
<% end %>
```

Note: `turbo:before-cache` 이벤트를 사용해야 Turbo 캐시가 React 마운트 상태를 저장하지 않음.

Source: Turbo Drive event reference (https://turbo.hotwired.dev/reference/events)

### Pattern 4: ViewComponent 기본 구조

```ruby
# app/components/application_component.rb
class ApplicationComponent < ViewComponent::Base
end

# app/components/card_component.rb
class CardComponent < ApplicationComponent
  def initialize(title:, body: nil)
    @title = title
    @body = body
  end
end
```

```erb
<%# app/components/card_component.html.erb %>
<div class="bg-tv-white rounded-lg shadow-md p-6">
  <h2 class="text-tv-black font-bold text-lg"><%= @title %></h2>
  <% if @body %>
    <p class="text-tv-gray mt-2"><%= @body %></p>
  <% end %>
</div>
```

```erb
<%# 사용 예 (ERB 뷰에서) %>
<%= render(CardComponent.new(title: "제목", body: "본문")) %>
```

Source: https://github.com/viewcomponent/view_component/blob/main/docs/guide/getting-started.md

### Anti-Patterns to Avoid

- **importmap 태그와 vite 태그 동시 사용:** `javascript_importmap_tags`와 `vite_javascript_tag`를 함께 쓰면 JS가 두 번 로드되거나 충돌 발생
- **Turbo.visit 후 React 컴포넌트 미언마운트:** `turbo:before-cache` 없이 마운트만 하면 뒤로가기 시 캐시된 DOM에 이미 마운트된 React 상태가 남아 오류 발생
- **vite_ruby 엔트리포인트 외 파일에서 직접 tag helper 호출:** `app/frontend/entrypoints/` 디렉토리 외부 파일은 Vite가 번들링하지 않아 tag helper가 해당 파일을 인식 못 함
- **tailwindcss-rails와 @tailwindcss/vite 동시 사용:** 두 CSS 빌더가 같은 출력을 생성하여 충돌 및 중복 발생

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stimulus 컨트롤러 자동 등록 | 파일 목록 수동 import | stimulus-vite-helpers | import.meta.glob 기반 자동화, HMR 지원 |
| React HMR | 커스텀 hot reload 로직 | @vitejs/plugin-react | Fast Refresh 프로토콜 구현, 상태 보존 |
| ViewComponent 테스트 | 직접 render 어설션 | ViewComponent::TestCase + render_inline | Capybara 매처 지원, 격리된 컴포넌트 테스트 |
| Turbo+React 마운트 관리 | 커스텀 router | turbo:load + turbo:before-cache 이벤트 | Turbo 공식 이벤트, 캐시 사이클 정확히 반영 |

**Key insight:** React-in-Turbo 마운트 패턴에서 `turbo:before-render` 대신 `turbo:before-cache`를 사용해야 한다. `turbo:before-render`는 Turbo 캐시를 쓸 때 두 번 발화할 수 있으나, `turbo:before-cache`는 캐시 저장 직전에 정확히 한 번 발화한다.

---

## Common Pitfalls

### Pitfall 1: tailwindcss-rails watch 프로세스 충돌

**What goes wrong:** vite_ruby 추가 후 Procfile.dev에서 `css: bin/rails tailwindcss:watch`를 그대로 두면, Vite와 tailwindcss-rails가 각각 CSS를 처리하려 해서 빌드 출력 경로가 달라지거나 CSS가 두 군데서 serve된다.

**Why it happens:** tailwindcss-rails는 `app/assets/tailwind/application.css`를 입력으로 받아 `app/assets/builds/application.css`를 출력한다. vite_ruby는 `app/frontend/`를 sourceCodeDir로 사용하므로 기존 CSS 파일을 인식하지 못한다.

**How to avoid:** vite_ruby 도입 시 tailwindcss-rails gem을 Gemfile에서 제거하고, Tailwind CSS는 `@tailwindcss/vite` npm 패키지로 처리한다. 기존 `app/assets/tailwind/application.css`의 `@theme` 블록을 `app/frontend/entrypoints/application.css`로 이전한다.

**Warning signs:** Procfile.dev에 `css:` 라인이 남아있거나, `stylesheet_link_tag :app`이 레이아웃에 남아있는 경우

---

### Pitfall 2: importmap-rails gem 미제거

**What goes wrong:** vite_ruby 추가 후 importmap-rails를 Gemfile에서 제거하지 않으면, `config/importmap.rb`가 남아있고 layout에서 두 JS 시스템이 충돌한다.

**Why it happens:** importmap-rails는 Rails 8 default로 포함되어 있어 제거하지 않으면 `javascript_importmap_tags`가 계속 `<script type="importmap">`을 렌더링한다.

**How to avoid:** Gemfile에서 `gem "importmap-rails"` 제거, `config/importmap.rb` 삭제, layout에서 `javascript_importmap_tags` 제거 후 vite 태그 추가.

**Warning signs:** Rails 콘솔에서 `ImportmapRails`가 로드되거나, HTML 소스에 `<script type="importmap">`이 남아있는 경우

---

### Pitfall 3: React root 중복 마운트

**What goes wrong:** `turbo:load`에서 `createRoot(el).render()`를 호출할 때 root 레퍼런스를 저장하지 않으면, 같은 페이지 방문 시마다 새 root를 생성하여 React warning 발생.

**Why it happens:** Turbo Drive는 SPA처럼 동작하여 `turbo:load`가 매 navigation마다 발화한다. React 18의 `createRoot`는 같은 DOM 노드에 두 번 호출하면 경고 발생.

**How to avoid:** module 스코프에 `let root = null`로 선언하고, 마운트 전 `if (el && !root)` 체크. `turbo:before-cache`에서 `root.unmount(); root = null` 처리.

**Warning signs:** 브라우저 콘솔에 `"Warning: createRoot(): ... already using createRoot"` 메시지

---

### Pitfall 4: SQLite WAL이 개발 DB에만 적용되고 queue/cache/cable DB에 미적용

**What goes wrong:** database.yml에 queue/cache/cable DB를 추가해도 WAL 모드 pragma가 해당 DB에 적용되지 않을 수 있다.

**Why it happens:** Rails 8.1 + sqlite3 2.x에서 WAL 모드는 primary DB에 자동 적용되지만, 새로 생성하는 DB에는 `db:create` 시점에 pragmas 상속 여부 확인 필요.

**How to avoid:** `rails db:create:all` 후 각 DB 파일에 대해 PRAGMA journal_mode 확인. SQLite에서 WAL 모드는 파일 레벨로 지속(persistent)되므로 한 번 설정하면 유지된다. `database.yml`에 `pragmas:` 섹션 명시적 추가 권장.

**Warning signs:** `sqlite3 storage/development_queue.sqlite3 "PRAGMA journal_mode;"` 결과가 `wal`이 아닌 `delete`로 나오는 경우

---

## Code Examples

Verified patterns from official sources:

### vite.config.ts (React + Tailwind v4 + Rails)

```typescript
// vite.config.ts
import { defineConfig } from "vite"
import ViteRails from "vite-plugin-rails"
import react from "@vitejs/plugin-react"
import tailwindcss from "@tailwindcss/vite"

export default defineConfig({
  plugins: [
    tailwindcss(),
    react(),
    ViteRails({
      envVars: { RAILS_ENV: "development" },
      envOptions: { defineOn: "import.meta.env" },
      fullReload: {
        additionalPaths: ["config/routes.rb", "app/views/**/*"],
        delay: 300,
      },
    }),
  ],
})
```

Source: kitemetric.com 가이드 + vite_ruby 공식 문서 기반

---

### config/vite.json

```json
{
  "all": {
    "watchAdditionalPaths": []
  },
  "development": {
    "autoBuild": true,
    "publicOutputDir": "vite-dev",
    "port": 3036
  },
  "test": {
    "autoBuild": true,
    "publicOutputDir": "vite-test",
    "port": 3037
  }
}
```

Source: https://vite-ruby.netlify.app/config/ (Context7)

---

### app/frontend/entrypoints/application.js

```javascript
// Turbo + Stimulus (기존 기능 유지)
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { registerControllers } from "stimulus-vite-helpers"

const application = Application.start()
const controllers = import.meta.glob("../controllers/**/*_controller.js", { eager: true })
registerControllers(application, controllers)
```

Source: https://github.com/ElMassimo/stimulus-vite-helpers (Context7)

---

### application.html.erb 레이아웃 변경

```erb
<%# 제거: stylesheet_link_tag :app %>
<%# 제거: javascript_importmap_tags %>

<%# 추가: vite 태그 %>
<%= vite_client_tag %>
<%= vite_react_refresh_tag %>
<%= vite_javascript_tag 'application' %>
```

Source: https://vite-ruby.netlify.app/guide/rails.html (Context7)

---

### database.yml (개발 환경 Solid DB 추가)

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  cache:
    <<: *default
    database: storage/development_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/development_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: storage/development_cable.sqlite3
    migrations_paths: db/cable_migrate

test:
  <<: *default
  database: storage/test.sqlite3

production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  cache:
    <<: *default
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: storage/production_cable.sqlite3
    migrations_paths: db/cable_migrate
```

Source: scottw.com/solid-queue-in-development + fractaledmind.com 기반

---

### config/environments/development.rb 추가 (Solid 어댑터 활성화)

```ruby
# Solid Queue 개발 환경 활성화
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }

# Solid Cache 개발 환경 활성화 (선택적 - 현재 memory_store로도 충분)
# config.cache_store = :solid_cache_store

# Solid Cable 개발 환경 활성화 (선택적 - 현재 async로도 충분)
# config.action_cable.cable = { adapter: "solid_cable", ... }
```

Source: scottw.com/solid-queue-in-development (MEDIUM confidence)

---

### ViewComponent 첫 컴포넌트

```ruby
# app/components/application_component.rb
class ApplicationComponent < ViewComponent::Base
end
```

```bash
# 제너레이터 사용
bin/rails generate view_component:component Card title body
```

```ruby
# 생성된 app/components/card_component.rb
class CardComponent < ApplicationComponent
  def initialize(title:, body: nil)
    @title = title
    @body = body
  end
end
```

```erb
<%# app/components/card_component.html.erb %>
<div class="bg-tv-white rounded-lg shadow-md p-6">
  <h2 class="font-bold text-lg text-tv-black"><%= @title %></h2>
  <% if @body %>
    <p class="mt-2 text-tv-gray"><%= @body %></p>
  <% end %>
</div>
```

Source: https://github.com/viewcomponent/view_component/blob/main/docs/guide/getting-started.md (Context7)

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Webpacker | vite_ruby | Rails 7+ | HMR 지원, 빠른 빌드, ESM 네이티브 |
| importmap-rails | vite_ruby (npm 에코시스템) | Rails 8.1로 마이그 시 | JSX, TypeScript, npm 패키지 사용 가능 |
| tailwindcss-rails gem | @tailwindcss/vite npm 플러그인 | Tailwind v4 + Vite 조합 시 | Vite HMR에 통합, 별도 watch 프로세스 불필요 |
| Sprockets | Propshaft (→ 제거 예정) | Rails 7+ | Propshaft도 vite 전환 시 제거 가능 |
| SQLite DELETE 저널 | WAL 모드 (Rails 7.1+) | Rails 7.1 | 읽기 동시성 향상, sqlite3 gem 2.x에서 자동 적용 |
| ViewComponent 2.x/3.x | ViewComponent 4.x | 2024 말~2025 | 4.4.0 최신 버전, Rails 8 지원 |

**Deprecated/outdated:**

- `@hotwired/stimulus-loading` (eagerLoadControllersFrom): vite_ruby에서는 stimulus-vite-helpers로 대체
- `pin_all_from` in importmap.rb: vite_ruby에서는 import.meta.glob으로 대체
- `javascript_importmap_tags` 헬퍼: vite_javascript_tag로 대체
- `stylesheet_link_tag :app`: vite_stylesheet_tag 또는 CSS를 JS entrypoint에서 import로 대체

---

## Open Questions

1. **tailwindcss-rails 제거 시 기존 Tailwind 설정(@theme 블록) 이전 범위**
   - What we know: 현재 `app/assets/tailwind/application.css`에 `@theme` 블록으로 디자인 토큰이 정의되어 있음. `@import "tailwindcss"` 포함.
   - What's unclear: `@tailwindcss/vite`로 전환 시 이 파일을 `app/frontend/`로 그대로 이전하면 되는지, 아니면 추가 설정 필요한지.
   - Recommendation: 파일을 `app/frontend/entrypoints/application.css`로 이동 후 vite.config.ts에서 css 파일을 직접 처리하게 설정. `@import "tailwindcss"` + `@theme {}` 블록은 Tailwind v4의 표준 방식이므로 그대로 동작할 것으로 예상 (HIGH confidence).

2. **Propshaft 제거 가능 여부**
   - What we know: 현재 사용 중인 gem 중 Propshaft에 명시적으로 의존하는 것은 없음. tailwindcss-rails gem 제거 시 Propshaft 의존성도 사라짐. kamal gem은 Propshaft와 직접 의존 관계 없음.
   - What's unclear: 현재 `app/assets/` 디렉토리의 이미지/fonts 등 정적 에셋을 Propshaft가 서비스하고 있는지, 없애도 되는지.
   - Recommendation: Propshaft 제거 후 정적 에셋은 `app/frontend/images/` 또는 `public/`으로 이전. vite_ruby가 `~/{images}/**/*`를 additionalEntrypoints로 처리 가능.

3. **Solid Queue/Cache/Cable 개발 환경 활성화 범위**
   - What we know: Phase 1 요구사항은 "별도 SQLite 파일을 사용하며 WAL 모드가 활성화"이다. 현재 개발 환경은 async 어댑터(queue), memory_store(cache), async(cable)를 사용함.
   - What's unclear: Phase 1 성공 기준이 "별도 DB 파일 존재 + WAL 확인"인지, 아니면 "실제로 Solid 어댑터가 개발에서도 동작"인지.
   - Recommendation: 성공 기준 재검토. 최소한 DB 파일 생성 + WAL 확인까지는 필수. Solid Queue를 개발 환경에서 실제 활성화는 선택적으로 진행.

---

## Sources

### Primary (HIGH confidence)

- Context7 `/elmassimo/vite_ruby` - 설치, 태그 헬퍼, vite.json 설정, Stimulus HMR, Propshaft 공존
- Context7 `/viewcomponent/view_component` - 설치, 제너레이터, ERB 렌더링, 슬롯, 테스트
- RubyGems API - vite_rails 3.0.20, view_component 4.4.0 버전 확인
- 로컬 프로젝트 직접 검사 - sqlite3 2.9.0, Rails 8.1.2, Propshaft 1.3.1, Ruby 3.3.10
- `rails runner "PRAGMA journal_mode"` - 현재 개발 DB에서 WAL 이미 활성화 확인

### Secondary (MEDIUM confidence)

- fractaledmind.com/2023/09/07/enhancing-rails-sqlite-fine-tuning - WAL pragma 설정 예시
- joyofrails.com/articles/what-you-need-to-know-about-sqlite - Rails 8 WAL 자동 적용 확인
- scottw.com/solid-queue-in-development - Solid Queue 개발 환경 활성화 패턴
- kitemetric.com/blogs/setting-up-a-rails-8-app-with-vite-and-tailwind-css-4 - vite.config.ts 예시
- turbo.hotwired.dev/reference/events - turbo:load, turbo:before-cache 이벤트 레퍼런스

### Tertiary (LOW confidence)

- 없음 — 모든 핵심 사항은 공식 소스로 검증됨

---

## Metadata

**Confidence breakdown:**
- Standard stack (vite_ruby, view_component): HIGH — RubyGems + Context7 문서 기반
- SQLite WAL 자동 적용: HIGH — 로컬 프로젝트에서 직접 `PRAGMA journal_mode` 실행 확인
- Solid 별도 DB 패턴 (개발환경): MEDIUM — 공식 docs보다는 검증된 커뮤니티 가이드 기반
- Turbo + React 마운트 패턴: MEDIUM — Turbo 공식 이벤트 레퍼런스 기반이나 통합 예시는 커뮤니티 소스
- tailwindcss-rails 제거 + @tailwindcss/vite 전환: MEDIUM — 다수 가이드에서 동일 패턴 확인

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (vite_ruby, view_component는 안정적이므로 30일)

---

## 현재 프로젝트 상태 요약 (구현 시 참고)

실제 마이그레이션을 위해 현재 상태를 파악:

| 항목 | 현재 상태 | 목표 상태 |
|------|-----------|-----------|
| JS 빌드 | importmap-rails (config/importmap.rb) | vite_ruby (vite.config.ts) |
| Stimulus 등록 | eagerLoadControllersFrom (app/javascript/controllers/index.js) | stimulus-vite-helpers + import.meta.glob |
| CSS 빌드 | tailwindcss-rails (app/assets/tailwind/application.css) | @tailwindcss/vite (app/frontend/entrypoints/application.css) |
| Layout 태그 | javascript_importmap_tags + stylesheet_link_tag :app | vite_client_tag + vite_react_refresh_tag + vite_javascript_tag |
| SQLite primary | WAL 이미 활성화됨 (sqlite3 gem 2.9.0 자동) | 유지 |
| SQLite Solid DB | 개발 환경에 별도 DB 없음 (production 전용) | development에도 queue/cache/cable DB 추가 |
| Solid Queue | 개발: async | 개발: solid_queue (DB: development_queue.sqlite3) |
| Solid Cache | 개발: memory_store | 개발: solid_cache (DB: development_cache.sqlite3) — 선택적 |
| Solid Cable | 개발: async | 개발: solid_cable (DB: development_cable.sqlite3) — 선택적 |
| ViewComponent | 미설치 | view_component 4.4.0 + CardComponent |
| Propshaft | 1.3.1 설치됨 | 제거 가능 (tailwindcss-rails 제거 후) |
| React | 미설치 | react + react-dom, turbo:load 기반 마운트 |
