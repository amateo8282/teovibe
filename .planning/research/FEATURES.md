# Feature Research

**Domain:** Admin CMS 고도화 — Rails 기반 블로그 커뮤니티 플랫폼 (v1.1 Milestone)
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH

## Context: What Already Exists (Not in Scope)

이 파일은 v1.1 밀스톤의 신규 기능에만 집중한다. 이미 구현된 항목은 제외.

- 6개 하드코딩 게시판 카테고리 (blog, tutorial, free_board, qna, portfolio, notice)
- Admin CMS CRUD (게시글, 사용자, 스킬팩, 문의, 랜딩섹션)
- rhino-editor 리치 에디터 (이미지 업로드, 버블 메뉴)
- Solid Queue 설정 완료
- Admin 분석 대시보드 (chartkick + groupdate)

---

## Feature Landscape

### Table Stakes (Users Expect These)

CMS 관리자가 당연히 있을 것이라 기대하는 기능들. 없으면 "미완성" 느낌을 준다.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 카테고리 CRUD (생성/수정/삭제/순서) | 모든 CMS는 카테고리를 동적으로 관리한다. 하드코딩된 enum은 배포 없이 변경 불가능하여 운영 비효율 발생 | MEDIUM | Post.category enum을 DB 테이블(Category 모델)로 이관. acts_as_list로 position 관리. 기존 게시글과 외래키 연결 필요 |
| 카테고리별 작성 권한 토글 (관리자 전용) | Discourse, Ghost, WordPress 모두 카테고리별 게시 권한 설정을 제공. "공지" "블로그" 등 일부 카테고리는 관리자만 작성해야 함 | LOW | Category 모델에 `admin_only_write: boolean` 컬럼 추가. PostsController#new에서 권한 체크 |
| 게시글 예약 발행 | Ghost, WordPress 등 모든 블로그 플랫폼이 지원. 운영자가 콘텐츠를 미리 작성해두고 최적 시간에 자동 발행 | MEDIUM | Post에 `publish_at: datetime` 컬럼. 현재 status enum에 `scheduled` 추가. Solid Queue로 발행 잡 예약 |
| 예약 발행 날짜/시간 UI 피커 | datetime 필드에 원시 텍스트 입력은 UX 실패. 모든 CMS는 캘린더+시간 피커를 제공 | LOW | Stimulus controller + flatpickr. `enableTime: true`, `altInput: true`로 사람 친화적 표시 + 서버 전송 포맷 분리 |
| 스킬팩 카테고리 동적 관리 | 게시판과 동일한 패턴. SkillPack도 현재 하드코딩된 카테고리 사용 추정 | MEDIUM | SkillPackCategory 모델 별도 생성. 게시판 카테고리와 독립적으로 관리 |

### Differentiators (Competitive Advantage)

TeoVibe의 1인 운영 효율성을 극대화하는 차별 기능. 없어도 작동하지만 있으면 운영 부담을 크게 줄임.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AI 초안 작성 2단계 (주제 → 개요 → 본문) | 1인 운영자의 콘텐츠 생산 속도를 2-3배 향상. 빈 페이지 앞에서의 저항감 제거. Ghost나 WordPress는 AI 초안 기능 없음 — 차별점이자 운영 효율화 | HIGH | Anthropic Claude API. 1단계: 주제 입력 → 개요(H2 섹션 목록) 생성. 2단계: 개요 승인 후 본문 생성. rhino-editor에 초안 삽입 |
| SEO/AEO 최적화 시스템 프롬프트 | 단순 글 생성이 아니라 검색 노출 최적화까지 고려. FAQPage 스키마 호환 구조, 40-60자 직접 답변 단락, H2/H3 계층 구조를 프롬프트에 내장 | MEDIUM | 시스템 프롬프트에 AEO 체크리스트 포함. FAQ 섹션 자동 생성 옵션. 별도 설정 UI 불필요 — 프롬프트 엔지니어링으로 해결 |
| 스트리밍 응답 (실시간 타이핑 효과) | GPT/Claude 웹 인터페이스처럼 글자가 타이핑되는 UX. 응답 대기 시간의 체감 불안감을 제거 | HIGH | ActionController::Live + SSE 또는 Turbo Streams를 통한 청크 스트리밍. Anthropic API `stream: true` 파라미터 사용 |
| 카테고리 드래그앤드롭 순서 변경 | UX 품질의 차이. 버튼 클릭 위/아래 이동보다 드래그앤드롭이 훨씬 직관적. Notion, Ghost 모두 사용 | MEDIUM | Sortable.js + Stimulus controller. position 컬럼 일괄 업데이트 API 엔드포인트 |

### Anti-Features (Commonly Requested, Often Problematic)

요청받을 수 있지만 현재 맥락에서 구현하면 안 되는 기능들.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| 사용자별 카테고리 구독/필터링 | "내가 관심 있는 카테고리만 보고 싶다"는 자연스러운 요청 | 현재 v1.1 스코프가 Admin 운영 효율화에 집중됨. 사용자 선호도 저장 로직, UI 변경이 별도 마일스톤 수준의 작업 | 카테고리 목록 페이지에서 수동 필터링으로 충분 (이미 구현됨) |
| AI가 자동으로 게시글 전체 생성/발행 | 운영 자동화처럼 들림 | 품질 보증 없는 AI 발행은 브랜드 리스크. 관리자 승인 없는 발행은 1인 운영 철학에 어긋남 | 반드시 사람이 검토 후 수동 발행 또는 예약. AI는 "초안 보조"에 한정 |
| 반복 발행 스케줄 (cron 패턴) | "매주 월요일 오전 9시에 발행" 같은 요청 | 반복 발행은 게시글마다 내용이 달라야 하므로 자동화 의미 없음. solid_queue recurring은 동일 잡 반복용 | 단건 예약 발행으로 충분. recurring.yml은 시스템 유지보수 작업에만 사용 |
| 카테고리 계층 구조 (중첩 카테고리) | "메인 카테고리 > 서브카테고리" 구조 요청 | Ancestry 또는 closure_tree gem 필요. 현재 6개 평면 카테고리 구조에 과도한 복잡도. 쿼리, UI, breadcrumb 모두 복잡해짐 | 평면 카테고리 + 태그 시스템으로 대응 (태그는 future 항목) |
| AI 생성 콘텐츠 자동 SEO 제출 (Google Indexing API) | AI로 쓴 글을 구글에 빠르게 색인 | 대량 AI 콘텐츠 자동 제출은 구글 스팸 정책 위반 가능성. 현재 사이트맵이 이미 존재 | 기존 사이트맵 + ping 엔드포인트로 충분 |

---

## Feature Dependencies

```
[카테고리 CRUD (게시판)]
    └──requires──> [Category 모델 + DB 마이그레이션]
                       └──requires──> [기존 Post.category enum 데이터 마이그레이션]
                       └──enables──> [관리자 전용 작성 토글]
                       └──enables──> [드래그앤드롭 순서 변경]

[카테고리 CRUD (스킬팩)]
    └──requires──> [SkillPackCategory 모델 + DB 마이그레이션]
                       └──독립적──> [게시판 카테고리와 별개 모델]

[게시글 예약 발행]
    └──requires──> [Post.publish_at 컬럼 + Post.status :scheduled 추가]
                       └──requires──> [PublishScheduledPostJob (ActiveJob)]
                                          └──requires──> [Solid Queue (이미 설정됨)]
    └──requires──> [날짜/시간 피커 UI (flatpickr Stimulus)]

[AI 초안 작성]
    └──requires──> [Anthropic API 클라이언트 (anthropic gem 또는 Faraday 직접)]
    └──requires──> [AI Draft 컨트롤러 + 라우트]
    └──enhances──> [rhino-editor (이미 설치됨) — 생성된 초안 삽입]
    └──optional──> [스트리밍 SSE (ActionController::Live)]
```

### Dependency Notes

- **Category 모델 이관이 가장 위험한 작업:** 기존 Post.category enum 데이터를 Category 모델 외래키로 마이그레이션해야 함. 마이그레이션 스크립트에서 `"blog" → category_id: 1` 매핑 필요. 롤백 계획 필수.
- **예약 발행은 Solid Queue 의존:** Solid Queue가 이미 설정되어 있으므로 추가 인프라 불필요. `set(wait_until: post.publish_at).perform_later(post.id)` 패턴으로 구현.
- **AI 초안이 rhino-editor와 독립적:** AI가 생성한 HTML/Markdown을 rhino-editor에 주입하는 것은 editor 인스턴스에 content를 set하는 JS 이벤트로 해결. editor 자체 수정 불필요.
- **스트리밍은 선택적 개선:** 스트리밍 없이 일반 POST → 응답 패턴으로도 동작함. 스트리밍은 UX 향상이지 기능 요구사항이 아님. 구현 복잡도를 감안해 후순위로 처리 가능.

---

## 기능별 상세 동작 분석

### 1. 동적 카테고리 관리 + 관리자 전용 작성 토글

**사용자 행동 시나리오:**
1. Admin이 `/admin/categories` 접근
2. "새 카테고리" 버튼 클릭 → 이름, 슬러그, 설명, 관리자 전용 여부 입력
3. 생성된 카테고리가 목록에 표시 — 드래그로 순서 변경
4. `admin_only_write: true`인 카테고리는 일반 사용자 게시글 작성 폼에 노출되지 않음
5. 카테고리 삭제 시 기존 게시글 처리 정책: "기본 카테고리로 이동" 또는 "삭제 불가 (게시글 있을 때)"

**관리자 전용 토글 UX 패턴:**
- 카테고리 목록에서 토글 스위치 (inline Turbo Stream 업데이트)
- 새 게시글 작성 시 `admin_only_write` 카테고리는 일반 사용자에게 숨김
- 실수 방지: 이미 게시글이 있는 카테고리를 admin_only로 전환하면 경고 표시

**복잡도 요인:**
- enum → DB 테이블 이관 시 기존 데이터 정합성 (높은 위험)
- 순서 저장: `position` 컬럼 + acts_as_list 또는 직접 구현
- Sortable.js AJAX 업데이트: position 배열을 PATCH 한 번에 업데이트

### 2. AI 초안 작성 (2단계: 주제 → 개요 → 본문)

**사용자 행동 시나리오:**
1. Admin이 게시글 작성 폼 하단 "AI 초안 작성" 섹션 접근
2. **1단계:** 주제/키워드 입력 (예: "바이브코딩으로 수익화하는 5가지 방법") → "개요 생성" 클릭
3. 서버가 Anthropic API 호출 → 섹션 개요(H2 목록 + 각 섹션 요약 1문장) 반환
4. Admin이 개요 검토 — 섹션 이름 수정, 순서 변경, 삭제 가능
5. **2단계:** "본문 생성" 클릭 → 승인된 개요 기반으로 전체 본문 생성
6. 생성된 본문이 rhino-editor에 삽입됨 → Admin이 편집 후 저장/예약 발행

**SEO/AEO 시스템 프롬프트 핵심 요소:**
- H2/H3 명확한 계층 구조 (Google SGE가 계층 구조를 인식)
- 각 섹션 첫 단락에 40-60자 직접 답변 ("What is X? X is...")
- FAQ 섹션 자동 포함 (FAQPage 스키마 마크업과 호환)
- 타겟 키워드를 자연스럽게 첫 100자 내 포함
- 한국어 콘텐츠 특화 (구어체/문어체 혼용 주의)

**API 구현 패턴:**
```
POST /admin/ai_drafts
Body: { topic: "...", target_keywords: [...], category: "blog", step: "outline" | "body", outline: {...} }
Response: { content: "...", step: "outline" | "body" }
```

**스트리밍 구현 (선택적):**
- `stream: true` Anthropic API 파라미터
- Rails `ActionController::Live` + `response.stream.write("data: #{chunk}\n\n")`
- 프론트엔드: `EventSource` API로 청크 수신 → rhino-editor에 점진적 삽입

**복잡도 요인:**
- Anthropic API 비용 관리 (응답 토큰 cap 설정 권장: max_tokens: 4000)
- 스트리밍과 Puma의 connection thread 관리 (streaming은 별도 고려 필요)
- rhino-editor에 외부 HTML 삽입: editor.commands.setContent() 또는 insertContent() 호출

### 3. 게시글 예약 발행 (날짜/시간 피커)

**사용자 행동 시나리오:**
1. Admin이 게시글 작성/수정 폼에서 "발행 예약" 옵션 선택
2. 날짜+시간 피커 표시 (flatpickr: 현재 시간 이후만 선택 가능, `minDate: "today"`)
3. "예약 발행" 저장 클릭 → Post.status가 `:scheduled`, `publish_at`에 선택한 시간 저장
4. Solid Queue 잡이 `publish_at` 시각에 `Post.status = :published`로 변경
5. Admin 게시글 목록에서 "예약됨" 상태 + 발행 예정 시각 표시
6. 예약 취소: "예약 해제" 버튼 → status를 `:draft`로, `publish_at`을 nil로 변경

**Status 상태 흐름:**
```
:draft → [즉시 발행] → :published
:draft → [예약 설정] → :scheduled → [시간 도래] → :published
:scheduled → [예약 취소] → :draft
:published → [게시 취소] → :draft (관리자 수동)
```

**Solid Queue 잡 구현:**
```ruby
# app/jobs/publish_scheduled_post_job.rb
class PublishScheduledPostJob < ApplicationJob
  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.scheduled?
    return if post.publish_at > Time.current  # 재스케줄된 경우 안전장치
    post.update!(status: :published, published_at: Time.current)
  end
end

# 예약 시:
PublishScheduledPostJob.set(wait_until: post.publish_at).perform_later(post.id)
```

**flatpickr UX 설정:**
- `enableTime: true` — 시간도 선택 가능
- `altInput: true` — 사람 친화적 표시 ("2026년 3월 15일 오전 10:00") + 서버 전송용 ISO 포맷 숨김
- `minDate: "today"`, `minTime: "now"` — 과거 시간 선택 방지
- `locale: "ko"` — 한국어 UI
- 시간대: 서버는 UTC 저장, 표시는 KST (UTC+9) 변환

**복잡도 요인:**
- 시간대 처리: Ruby `Time.zone = "Seoul"` 설정 + 사용자 입력을 UTC로 변환
- 예약 취소 후 잡이 이미 큐에 있는 경우 처리 (Solid Queue에서 잡 취소 또는 perform 시 status 체크로 무시)
- 예약 변경 시 기존 잡 취소 + 새 잡 등록 패턴

---

## MVP Definition

### Launch With (v1.1 이번 밀스톤)

- [ ] Category 모델 생성 + Post enum 이관 마이그레이션 — 모든 동적 카테고리 기능의 기반
- [ ] Admin 카테고리 CRUD UI + 관리자 전용 토글 — 표 스테이크
- [ ] 카테고리 순서 변경 (position + acts_as_list) — UX 완성도
- [ ] 스킬팩 카테고리 별도 CRUD — 독립 기능, Category 모델과 유사 패턴
- [ ] Post publish_at + :scheduled status 추가 — 예약 발행 기반
- [ ] PublishScheduledPostJob + Solid Queue 연동 — 예약 발행 백엔드
- [ ] flatpickr 날짜/시간 피커 UI — 예약 발행 프론트엔드
- [ ] AI 초안 1단계 (주제 → 개요) — 핵심 가치
- [ ] AI 초안 2단계 (개요 → 본문) + rhino-editor 삽입 — 핵심 가치

### Add After Validation (v1.x)

- [ ] AI 초안 스트리밍 응답 — UX 개선, 기능 자체는 이미 동작
- [ ] 카테고리 드래그앤드롭 순서 변경 (Sortable.js) — 버튼 방식으로 먼저 출시
- [ ] 예약 발행 일괄 관리 (Admin 게시글 목록에서 예약 현황 일괄 확인) — 단건으로 먼저 검증

### Future Consideration (v2+)

- [ ] 태그 기반 콘텐츠 분류 (PROJECT.md future 항목) — 카테고리 안정화 후
- [ ] AI 초안 스타일/톤 선택 (전문적/친근한/SEO 집중) — 기본 동작 후 확장
- [ ] 게시글 예약 달력 뷰 — 규모 성장 후 의미 있음

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Category 모델 + enum 이관 | HIGH | HIGH | P1 (기반 작업) |
| Admin 카테고리 CRUD | HIGH | MEDIUM | P1 |
| 관리자 전용 작성 토글 | MEDIUM | LOW | P1 |
| 카테고리 position 순서 변경 | MEDIUM | MEDIUM | P1 |
| 스킬팩 카테고리 CRUD | MEDIUM | MEDIUM | P1 |
| 예약 발행 (백엔드 잡) | HIGH | MEDIUM | P1 |
| 예약 발행 (flatpickr UI) | HIGH | LOW | P1 |
| AI 초안 1단계 (개요 생성) | HIGH | MEDIUM | P1 |
| AI 초안 2단계 (본문 생성) | HIGH | MEDIUM | P1 |
| AI 스트리밍 응답 | MEDIUM | HIGH | P2 |
| 카테고리 드래그앤드롭 | MEDIUM | MEDIUM | P2 |

**Priority key:**
- P1: 이번 밀스톤 필수
- P2: 이번 밀스톤 내 여유 시 추가
- P3: 차기 밀스톤

---

## Competitor Feature Analysis

| Feature | Ghost | WordPress Admin | TeoVibe Current | TeoVibe v1.1 Target |
|---------|-------|-----------------|-----------------|---------------------|
| 동적 카테고리 CRUD | Yes (Tags/Categories) | Yes (Categories) | 하드코딩 enum | DB 기반 Category 모델 |
| 카테고리 순서 변경 | Yes (drag) | Yes (drag) | 없음 | position + acts_as_list |
| 카테고리별 작성 권한 | No (모두 작성 가능) | Yes (roles per category) | 없음 | admin_only_write 토글 |
| AI 초안 작성 | No | 써드파티 플러그인만 | 없음 | Anthropic 네이티브 통합 |
| 예약 발행 | Yes | Yes | 없음 | Solid Queue 기반 |
| 예약 발행 UI | 캘린더 피커 | 캘린더 피커 | 없음 | flatpickr Stimulus |

**Key insight:** Ghost와 WordPress 모두 동적 카테고리와 예약 발행을 표 스테이크로 제공한다. AI 초안은 Ghost도 네이티브로 없음 — 이 부분이 실질적 차별점이 될 수 있다. 단, AI 초안은 "도구"일 뿐이고 최종 콘텐츠 품질은 사람의 편집에 달려 있다.

---

## Sources

- Anthropic API 스트리밍 공식 문서: [https://platform.claude.com/docs/en/build-with-claude/streaming](https://platform.claude.com/docs/en/build-with-claude/streaming) — HIGH confidence (공식 문서)
- Solid Queue 공식 GitHub: [https://github.com/rails/solid_queue](https://github.com/rails/solid_queue) — HIGH confidence (공식)
- Solid Queue 실전 가이드 (2025): [https://blog.appsignal.com/2025/06/18/a-deep-dive-into-solid-queue-for-ruby-on-rails.html](https://blog.appsignal.com/2025/06/18/a-deep-dive-into-solid-queue-for-ruby-on-rails.html) — HIGH confidence (AppSignal, 검증된 Rails 블로그)
- Dynamic scheduled tasks Solid Queue issue: [https://github.com/rails/solid_queue/issues/186](https://github.com/rails/solid_queue/issues/186) — HIGH confidence (공식 GitHub)
- flatpickr 공식 문서: [https://flatpickr.js.org/](https://flatpickr.js.org/) — HIGH confidence (공식)
- stimulus-flatpickr wrapper: [https://github.com/adrienpoly/stimulus-flatpickr](https://github.com/adrienpoly/stimulus-flatpickr) — MEDIUM confidence (커뮤니티 라이브러리)
- AEO 완전 가이드 2025: [https://cxl.com/blog/answer-engine-optimization-aeo-the-comprehensive-guide/](https://cxl.com/blog/answer-engine-optimization-aeo-the-comprehensive-guide/) — HIGH confidence (CXL, 신뢰성 높은 마케팅 교육 기관)
- FAQPage 스키마 + AI 검색 인용률: [https://www.frase.io/blog/faq-schema-ai-search-geo-aeo](https://www.frase.io/blog/faq-schema-ai-search-geo-aeo) — MEDIUM confidence (WebSearch, 단일 출처)
- Time picker UX best practices 2025: [https://www.eleken.co/blog-posts/time-picker-ux](https://www.eleken.co/blog-posts/time-picker-ux) — MEDIUM confidence (WebSearch)
- GoRails 예약 발행 패턴: [https://gorails.com/forum/following-scheduling-post-episode-with-background-jobs](https://gorails.com/forum/following-scheduling-post-episode-with-background-jobs) — MEDIUM confidence (커뮤니티 포럼)

---

*Feature research for: Admin CMS 고도화 (v1.1) — 동적 카테고리, AI 초안, 예약 발행*
*Researched: 2026-02-28*
