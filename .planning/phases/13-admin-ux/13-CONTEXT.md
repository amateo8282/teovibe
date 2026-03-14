# Phase 13: Admin 에디터 UX - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Admin 게시글 작성/수정 폼을 2단 레이아웃으로 개선한다. 메타 정보 패널을 sticky로 고정하고 모바일에서 1단 fallback을 제공한다. 모델/컨트롤러 변경 없는 순수 HTML+Tailwind 작업.

</domain>

<decisions>
## Implementation Decisions

### 2단 레이아웃 구조
- 왼쪽: 본문 에디터 (넓은 영역, flex-grow)
- 오른쪽: 메타 패널 (카테고리, 상태, 예약 발행 등 — 고정 너비 ~320px)
- Tailwind flex/grid로 구현, 별도 JS 불필요

### 메타 패널 sticky
- sticky top으로 스크롤 시 메타 패널이 뷰포트에 고정
- 본문이 길어져도 메타 패널은 항상 보임

### 모바일 fallback
- md 브레이크포인트(768px) 이하에서 1단 레이아웃으로 전환
- 모바일에서 메타 패널이 본문 위 또는 아래로 이동 (본문 아래가 자연스러움)

### Claude's Discretion
- 정확한 Tailwind 클래스 조합
- 메타 패널 내부 필드 순서/그룹핑
- sticky의 top offset 값
- 기존 폼 필드 재배치 방식

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- Admin 게시글 폼: `app/views/admin/posts/_form.html.erb` (현재 1단 레이아웃)
- Tailwind CSS v4 사용 중 — @theme 인라인 블록 방식
- Admin 레이아웃: `app/views/layouts/admin.html.erb`

### Established Patterns
- Admin 네임스페이스 컨트롤러/뷰 구조
- Turbo Stream 인라인 업데이트 패턴

### Integration Points
- `admin/posts/new.html.erb`, `admin/posts/edit.html.erb` — 폼 partial 렌더링
- `admin/posts/_form.html.erb` — 실제 레이아웃 변경 대상

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 13-admin-ux*
*Context gathered: 2026-03-14*
