---
description: 가장 최근 윤문 실행의 결과·점수·등급을 다시 보여주기 (재실행 없이)
argument-hint: [선택: run_id 지정 — 비우면 최신]
---

# /humanize-status — 최근 실행 결과 다시 보기

`_workspace/{run_id}/`의 산출물을 읽어 사용자에게 요약 표시한다. 새로 윤문하지 않는다.

## 인자
$ARGUMENTS

## 동작
1. 인자에 `run_id`(예: `2026-04-25-001`)가 있으면 그 폴더, 없으면 `_workspace/` 최신 디렉토리.
2. 폴더가 없으면 "이전 실행이 없습니다. `/humanize`로 시작하세요" 안내 후 종료.
3. 다음 파일들을 Read로 불러와 정리:
   - `01_input.txt` — 원본 길이
   - `02_detection.json` — 탐지 건수, 카테고리 분포, severity_weighted_score
   - `03_rewrite.md` (또는 최신 v2/v3) — 윤문본
   - `03_rewrite_diff.json` — 변경률
   - `04_fidelity_audit.json` — 의미 동등성 판정
   - `05_naturalness_review.json` — 잔존·과윤문, 품질 등급
   - `summary.md` (있으면) — 그대로 표시
4. 사용자에게 출력:
   - run_id, 실행 시각, 장르
   - 길이 변화(원본 → 윤문본 → 변경률)
   - 카테고리별 before/after 표
   - 점수: detection score 변화율, naturalness score
   - 품질 등급 (A/B/C/D)
   - 윤문본 본문 (마크다운 블록)
   - 다음 액션 안내: "추가 다듬기 → `/humanize-redo`, 새 글 → `/humanize`"

## 활용
- 터미널을 껐다 켰을 때 마지막 결과 다시 확인
- 어느 단계에서 멈췄는지 진단
