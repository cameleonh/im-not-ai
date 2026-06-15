---
description: 윤문 없이 AI 티만 탐지 — 어디가 어떤 패턴인지 카테고리·심각도별로 리포트만 생성
argument-hint: [탐지할 텍스트 또는 파일 경로]
---

# /humanize-detect — 탐지 단계만 실행

`humanize-korean` 스킬의 Phase 1~2까지만 실행한다. 윤문은 하지 않는다.

## 입력
$ARGUMENTS

## 동작
1. 인자 검증: 비었으면 "탐지할 텍스트를 붙여넣어 주세요" 안내.
2. 새 `run_id` 생성 → `_workspace/{run_id}/01_input.txt` 저장.
3. `ai-tell-detector` 에이전트를 `Agent` 도구(`model: "opus"`)로 호출:
   - `taxonomy_path`: humanize-korean 스킬 디렉토리의 `references/ai-tell-taxonomy.md` (plugin/local 양쪽 호환). 못 찾으면 Glob `**/ai-tell-taxonomy.md` 로 탐색.
   - `options: { min_severity: "S2", include_document_level: true }`
4. 산출물 `_workspace/{run_id}/02_detection.json` 생성 후 사용자에게 보고:
   - 총 탐지 건수, severity_weighted_score
   - 10대 카테고리별 건수 표 (A 번역투 / B 영어 인용 / C 구조 / D 관용구 / E 리듬 / F 수식 / G hedging / H 접속사 / I 형식명사 / J 시각 장식)
   - S1 결정적 패턴 목록 (있을 경우 전부, 위치 + before 스니펫)
   - "윤문까지 진행하려면 `/humanize` 또는 '이 결과로 윤문해줘'" 안내

## 활용
- AI 티 진단만 받고 직접 고치고 싶을 때
- 분류 체계 정확도 검증 (taxonomist 피드백용)
- 윤문 전에 "어디가 문제인지" 먼저 보고 싶을 때
