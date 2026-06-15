---
description: 과거 윤문 실행 목록을 표로 보기 (run_id, 시각, 장르, 등급, 길이 한눈에)
argument-hint: [선택: 개수 — 기본 20]
---

# /humanize-list — 과거 실행 목록

`_workspace/` 하위 모든 `{run_id}/` 디렉토리를 스캔해 최근 순으로 표시한다.

## 인자
$ARGUMENTS  (숫자만 전달되면 표시 개수, 기본 20)

## 동작
1. `_workspace/` 디렉토리 존재 확인. 없으면 "아직 실행 이력이 없습니다" 안내.
2. `ls -1t _workspace/` 로 최신 순 정렬, 상한(기본 20) 적용.
3. 각 폴더에 대해 가능한 정보 추출:
   - `run_id` (디렉토리 이름)
   - mtime (실행 시각)
   - `summary.md` 또는 `05_naturalness_review.json`에서 등급 (A/B/C/D)
   - `01_input.txt` 길이 → `final.md` (또는 최신 03_rewrite*) 길이 → 변경률
   - `02_detection.json`에서 총 탐지 건수
4. 표로 출력:

   | run_id | 실행 시각 | 장르 | 길이(원→윤) | 변경률 | 등급 | 비고 |
   |--------|----------|------|-------------|--------|------|------|

5. 표 아래 안내: "특정 run을 다시 보려면 `/humanize-status <run_id>`, 다시 다듬으려면 그 run을 최신으로 만들고 `/humanize-redo`"

## 활용
- 어떤 글이 어떻게 윤문됐는지 한 화면에 비교
- 등급 D였던 실행 추적
- 디스크 정리 전 어떤 run이 있었는지 파악
