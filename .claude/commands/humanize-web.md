---
description: 윤문 파이프라인을 웹 서비스(Next.js 15 + Vercel)로 확장하는 아키텍처·UX·API 설계
argument-hint: [선택: 추가 요구사항 — 예 "로그인 포함" "익명 MVP만" "Chrome Extension까지"]
---

# /humanize-web — 웹 서비스 확장 설계

`humanize-web-architect` 에이전트를 호출해 Next.js 15 App Router + Vercel Fluid Compute + AI Gateway 기반 웹앱 설계 문서를 생성한다.

## 사용자 요구
$ARGUMENTS

## 동작
1. `_workspace/web/` 디렉토리 준비 (없으면 생성).
2. `humanize-web-architect`를 `Agent` 도구(`subagent_type: humanize-web-architect`, `model: "opus"`)로 호출.
3. 입력 프롬프트:
   - `spec_path`: humanize-korean 스킬 디렉토리의 `references/web-service-spec.md` (plugin/local 양쪽 호환). 못 찾으면 Glob `**/web-service-spec.md`.
   - `user_requirements`: `$ARGUMENTS` (없으면 기본 v0 MVP)
   - `output_dir`: `_workspace/web/`
4. 산출물 (아키텍트가 생성):
   - `01_architecture.md` — 컴포넌트·데이터 흐름·배포 토폴로지
   - `02_api_spec.md` — `/api/detect`, `/api/rewrite` 엔드포인트 OpenAPI
   - `03_ux_flow.md` — 4화면(입력 → 탐지 하이라이트 → 좌우 diff → 윤문본 복사) 와이어플로우
   - 옵션: `04_auth_billing.md` (로그인·결제 요구 시), `05_chrome_ext.md` (확장 요청 시)
5. 결과 요약을 사용자에게 보고하고 다음 단계 안내:
   - "이 설계대로 구현할까요? 프런트엔드 엔지니어 에이전트가 필요하면 말씀해주세요"

## 로드맵 단계
- v0 MVP: 익명 단일 호출, Vercel 배포
- v1: Clerk 로그인 + Postgres 히스토리
- v2: Pro/Team 플랜, API 키, 웹훅
- v3: Chrome Extension (인라인 윤문)
- v4: 일본어·중국어 확장

인자에 단계 명시 없으면 v0 MVP 기준으로 설계한다.

## 주의
이 커맨드는 **설계 문서만** 생성한다. 실제 코드 구현은 별도 요청이 필요하다.
