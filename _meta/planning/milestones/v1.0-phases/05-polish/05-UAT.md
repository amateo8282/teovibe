---
status: passed
phase: 05-polish
source: 05-01-SUMMARY.md, 05-02-SUMMARY.md
started: 2026-02-22T13:30:00Z
updated: 2026-02-22T13:56:00Z
---

## Tests

### 1. 모바일 Navbar 알림/관리자 링크
expected: 모바일(375px)에서 햄버거 메뉴를 열면 알림 링크(읽지 않은 알림 배지 포함)와 관리자 링크(admin 계정인 경우), 글쓰기 버튼이 모두 표시된다.
result: pass

### 2. Admin 사이드바 모바일 기본 숨김 + 열기
expected: 모바일(375px)에서 Admin 페이지 접근 시 사이드바가 기본 숨김 상태이고, 햄버거 버튼을 누르면 왼쪽에서 사이드바가 슬라이드되며 나타난다.
result: pass

### 3. Admin 사이드바 오버레이 닫기
expected: Admin 사이드바가 열린 상태에서 반투명 오버레이 영역을 클릭하면 사이드바가 닫힌다.
result: pass

### 4. 데스크톱 레이아웃 변경 없음
expected: 데스크톱(1024px+)에서 공개 Navbar와 Admin 사이드바가 기존과 동일하게 정상 표시된다 (사이드바 항상 보임, 모바일 헤더 숨김).
result: pass

### 5. 커스텀 404 페이지
expected: 존재하지 않는 URL(예: /nonexistent-page)에 접근하면 tv-gold 색상의 큰 "404" 숫자와 "페이지를 찾을 수 없습니다" 한글 메시지, "홈으로 돌아가기" 링크가 표시된다. Navbar가 포함된 application 레이아웃으로 렌더링된다.
result: pass

### 6. 커스텀 500 에러 페이지
expected: 서버 오류 발생 시 tv-burgundy 색상의 큰 "500" 숫자와 "서버 오류가 발생했습니다" 한글 메시지가 표시된다. Navbar 없이 별도 심플 레이아웃으로 렌더링된다 (DB 의존 없음).
result: pass

### 7. 에러 페이지 홈 링크
expected: 404/500 에러 페이지에서 "홈으로 돌아가기" 링크를 클릭하면 홈 페이지(/)로 이동한다.
result: pass

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0

## Gaps

[none]

## Notes

- Tailwind v4 @source 디렉티브 누락으로 유틸리티 클래스 미생성 이슈 발견 → application.css에 @source 추가로 해결 (커밋 140d892)
- public/404.html, public/422.html, public/500.html 정적 파일이 커스텀 ErrorsController를 가리고 있어 삭제 필요 발견
- 개발 모드에서 커스텀 에러 페이지 테스트 시 consider_all_requests_local = false 임시 변경 필요 (테스트 후 복원 완료)
