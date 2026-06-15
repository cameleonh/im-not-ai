---
name: humanize-korean
description: Korean writing revision skill for naturalizing AI-like or translation-like Korean prose while preserving meaning, facts, numbers, names, citations, and genre. Use for "AI 같은 글 자연스럽게", "번역투 줄여줘", "한국어 문체 다듬어줘", "내용은 유지하고 톤만 정리", "논문 문체로 다듬어줘", "내 스타일로 써줘", and academic Korean/English style polish. This is a writing-quality workflow, not a detector-evasion or authorship-misrepresentation tool.
---

# Humanize Korean — 한국어 문체 자연화

한국어 글의 번역투, 기계적 병렬, 과한 접속, 리듬 단조로움, 부정확한 학술 문체를 줄여 자연스럽게 읽히도록 윤문한다. 목적은 글쓰기 품질 개선이며, AI 사용 사실을 숨기거나 탐지기를 우회하는 것이 아니다. 원래 5인 에이전트 파이프라인을 한 대화 안에서 4단계로 평탄화해 순차 수행한다.

## 철칙 (4대 불문율)

1. **의미 보존 (Fidelity First)** — 사실·주장·수치·고유명사·인용은 원문과 의미 동등하게 보존.
2. **근거 기반 (Span-Grounded)** — 모든 변경은 Step 1 탐지 finding에 연결. 탐지 없는 구간은 건드리지 않는다.
3. **장르 유지 (Tone Match)** — 칼럼을 문학으로, 리포트를 에세이로 옮기지 않는다.
4. **과윤문 금지 (No Over-Polish)** — 변경률 30% 초과 시 경고, 50% 초과 시 강제 중단.

## 입력 프로토콜

작업 시작 시 다음을 확인한다.

- **text**: 윤문할 한글 텍스트 (필수).
- **genre_hint**: 칼럼 | 리포트 | 블로그 | 공적. 없으면 첫 300자로 추정.
- **min_severity**: S1 | S2 | S3 (기본 **S2**).
- 한국어가 아니거나 100자 미만이면 신뢰도 경고 후 진행 여부를 묻는다.

심각도 기준: **S1 결정적**(한 번만 나와도 AI 확신, 무조건 제거) · **S2 강함**(1~2회 허용, 3회+ 반복 시 제거) · **S3 약함**(다른 패턴과 중첩될 때만).

## 4단계 절차 (순차)

먼저 번들된 references를 읽어 규칙을 내재화한다. (Claude.ai VM에서는 `bash`로 파일을 읽거나, 첨부된 스킬 폴더의 해당 파일을 참조한다.)

- `references/ai-tell-taxonomy.md` — 10대분류 × 40+ 패턴 (SSOT)
- `references/detection-guide.md` — 탐지 알고리즘·메트릭·JSON 스키마
- `references/rewriting-playbook.md` — 카테고리별 치환 레시피
- `references/audit-checklist.md` — 내용 감사 13항
- `references/review-rubric.md` — 자연스러움 등급·과윤문 신호·루프 정책
- `references/academic-style-sources.md` — 논문/학술 문체 요청 시만 로드하는 공개 PDF 기반 문체 원칙
- `references/user-style-profile.md` — 사용자 칼럼/논평 문체 요청 시만 로드하는 개인 문체 profile

### Step 1 — 탐지

`ai-tell-taxonomy.md` + `detection-guide.md`를 기준으로 입력을 전수 스캔한다.

- 각 finding: `category`(예: A-2) · `severity` · `text_span` · `start`/`end` offset · `reason` · `suggested_fix`.
- 문서 전역 패턴(E 리듬·C 구조)은 `scope: "document"`로 분리.
- 메트릭 계산: `ai_tell_density`, `severity_weighted_score`(detection-guide의 공식), 문장 길이 통계.
- **게이트**: 탐지 0건 또는 score < 10 → "AI 티가 거의 없습니다. 윤문 불필요"로 종료.

### Step 2 — 윤문

`rewriting-playbook.md`의 레시피를 따라 finding을 근거로만 수정한다.

- **카테고리 작업 순서**: D(관용구) → A(번역투) → I(형식명사) → G(Hedging)+A-10(가능형) → H(접속사) → F(수식) → B(영어) → C(구조)+J(장식) → E(리듬).
- 문단 단위로 커밋하고, 변경 전후 diff와 **변경률**을 기록한다.
- 변경률 30% 초과 → 경고 플래그, **50% 초과 → 중단**하고 마지막 안정본으로 롤백.
- 수치·고유명사·큰따옴표 인용·법률 조문은 **절대 변경 금지**.
- 논문·학술 문체 요청이면 `academic-style-sources.md`를 읽고, 특정 교수의 개인 문체가 아니라 일반 학술 관습(문제-방법-결과-함의, 조작적 정의, 신중한 인과 표현)만 적용한다.
- 사용자 문체 요청이면 `user-style-profile.md`를 읽고, 문장이나 표현을 베끼지 말고 구조·톤·논증 순서만 적용한다.

### Step 3 — 내용 감사

원문과 윤문본을 `audit-checklist.md`의 13항으로 대조한다.

- 절대 불변(고유명사·수치·날짜·직접인용·조문·수식) 위반 시 해당 edit **즉시 롤백**.
- 의미 보존(주장 방향·인과·주어·양화·극성·순서·누락/첨가) 위반 시 롤백 또는 헤지 보존 재작성.
- **의심은 롤백 편**: 의미 변경 가능성 5%+ 면 롤백 표시. 관용구 삭제는 관대하게, 구체화("필요"→"해야")는 엄격하게.
- 판정: `full_pass` / `conditional_pass`(롤백 후 재감사) / `fail`(전면 재작업).

### Step 4 — 자연스러움 리뷰

윤문본을 다시 탐지(Step 1 재실행)하고 `review-rubric.md`로 판정한다.

- **잔존**: S1 잔존 건수, S2 건수, `score_after` vs `score_before` 개선폭.
- **과윤문 5신호**: 장르 이탈 · 문학화 · 구어화 과다 · 리듬 과조작 · 어휘 대체 과다. 2개+ 동시 발견 시 과윤문 플래그.
- **품질 등급** (rubric 참조): A / B / C / D.

## 종합 판정 & 재작업 루프

Step 3·4 결과를 종합한다 (감사 AND 리뷰).

| 감사 | 리뷰 | 종합 | 후속 |
|------|------|------|------|
| full_pass | accept / accept_with_note | **승인** | 최종 출력 |
| full_pass | rewrite_round_2 | **2차 윤문** | target finding만 Step 2 재실행 |
| full_pass | rollback_and_rewrite | **롤백 후 재윤문** | 문제 edit 롤백 → Step 2 |
| conditional_pass | - | **롤백된 edit만 재시도** | Step 2 부분 재실행 |
| fail | - | **전면 재작업** | Step 2 전면 재실행 |

- **최대 3회 루프.** 3회 후에도 미해결이면 `hold_and_report`로 사람 검토를 권고한다.

## 최종 출력

1. **윤문본 전문** (마크다운 블록).
2. **요약표**: 원본/윤문본 길이 · 변경률 · 카테고리별 탐지 건수(before/after) · 점수 변화 · 품질 등급(A/B/C/D).
3. **주요 변경 하이라이트 3~5건** (before → after 대비).
4. 등급 B 이하일 때 "2차 윤문을 원하시면 말씀해주세요" 안내.

윤문 결과에 이의가 있으면 (특정 카테고리 과윤문·표현 유지 희망·장르 추정 오류 등) 해당 부분만 롤백·재처리한다.

## 주요 금기

- 수치·단위·날짜 변경 금지.
- 고유명사·제품명·모델명 변경 금지.
- 큰따옴표 인용문 내부 변경 금지.
- 법률 조문·학술 개념어 임의 치환 금지.
- 새로운 주장·사실·예시 추가, 원문 정보 누락 금지.
- 이모지·불릿·헤딩 제거는 장르 규칙을 따른다 (SNS·제품 카피는 유지 가능).

## 테스트 시나리오

- **정상 흐름**: ChatGPT 칼럼 초안(번역투 빈번 + 관용구 + "첫째·둘째·셋째" + 이모지) → 탐지 30~50건/score≥60 → 변경률 15~25% → 감사 full_pass → 리뷰 accept/등급 A·B.
- **과윤문**: 1차 변경률 40% → 감사 flag → 리뷰 장르 이탈 감지 → rollback_and_rewrite → 2차 변경률 22% 안정화.
- **S1 잔존**: 1차 후 "결론적으로" 2건 잔존 → rewrite_round_2 → 해당 finding만 재처리 → 잔존 0.
- **이미 사람 글**: 탐지 0건/score < 10 → Step 1 게이트에서 "윤문 불필요" 종료.
