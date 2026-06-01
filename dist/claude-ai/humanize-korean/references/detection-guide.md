# 탐지 가이드 (Detection Guide)

Step 1(탐지)의 실행 노하우. `ai-tell-taxonomy.md`의 10대분류 × 40+ 패턴을 입력 텍스트에 적용해 span 단위 finding과 문서 메트릭을 만든다.

## 탐지 원칙

- **스팬 정확성**: `start`·`end` offset은 원문 문자열 기준. 한 글자라도 어긋나면 윤문 단계에서 엉뚱한 구간을 고친다.
- **근거 제시**: 모든 finding은 taxonomy 항목 ID(예: `A-2`)와 연결한다.
- **넓게 탐지, 보수적 심각도**: 후보는 폭넓게 잡되, 확실한 것만 S1로 매긴다.
- **제외 대상**: 수치·고유명사·큰따옴표 직접 인용은 탐지하지 않는다 (playbook §3 Do-NOT).
- **장르 추정**: 첫 300자로 칼럼·리포트·블로그·공적을 추정해 맥락 플래그로 기록.

## 3단계 스캔

1. **1차 — 패턴 매칭**: A·B·D·F·G·H·I·J는 어휘·어미 기반. 키워드/어미 리스트로 후보를 폭넓게 추출.
2. **2차 — 문맥 검증**: 후보를 문장 맥락에서 재평가. 빈도로 심각도 조정 — 예: "통해"가 1회면 S2→S3 강등, 6회+ 면 S1 강화.
3. **3차 — 구조 분석**: C(불릿·헤딩·이모지)·E(문장 길이·종결어미 분포)는 문서 전역 통계로 판정. `scope: "document"`로 분리.
4. **중첩 해소**: 한 span에 복수 카테고리가 매치되면 심각도 높은 것만 남기고 나머지는 `related_findings`로.

## 메트릭 공식

- **ai_tell_density** = (탐지된 span의 총 글자 수) / (전체 글자 수).
- **severity_weighted_score**: 가중 합산 `S1×5 + S2×2 + S3×0.5`를 텍스트 길이로 정규화해 0~100으로 환산. 값이 클수록 AI 티가 짙다.
- **sentence_length_stats**: 문장 수, 평균, 표준편차. 표준편차가 낮으면(예: <7) `uniformity_warning: true` — E-1(리듬 균일) 신호.

## 출력 JSON 스키마

```json
{
  "meta": {
    "input_length": 1820,
    "estimated_genre": "칼럼",
    "sentence_count": 42,
    "sentence_length_stats": {"mean": 38.2, "stdev": 6.1, "uniformity_warning": true},
    "detected_count": 37,
    "ai_tell_density": 0.203,
    "severity_weighted_score": 71.5,
    "category_summary": {"A": 12, "B": 3, "C": 2, "D": 8, "E": 1, "F": 4, "G": 2, "H": 3, "I": 1, "J": 1}
  },
  "findings": [
    {
      "id": "f001",
      "category": "A-2",
      "category_label": "번역투: ~를 통해 남발",
      "severity": "S1",
      "scope": "span",
      "text_span": "데이터 분석을 통해",
      "start": 142,
      "end": 153,
      "reason": "'통해'가 본문에서 6회 반복되어 경로 서술이 기계적",
      "suggested_fix": "데이터를 분석해서"
    },
    {
      "id": "f014",
      "category": "E-1",
      "category_label": "리듬: 문장 길이 균일",
      "severity": "S2",
      "scope": "document",
      "reason": "문장 길이 표준편차 6.1로 낮음 — 모든 문장이 32~45자 구간에 몰림",
      "suggested_fix": "단문 1~2개 / 장문 1개를 각 문단에 투입해 리듬 변주"
    }
  ]
}
```

> Claude.ai 대화 흐름에서는 위 JSON을 파일로 강제 저장할 필요는 없다. 내부적으로 동일한 구조의 finding 목록을 유지해 Step 2~4에서 참조하면 된다.

## 엣지 케이스

- **한국어 아님**: "한국어 텍스트만 처리 가능"으로 안내하고 중단.
- **100자 미만**: "표본 부족, 탐지 신뢰도 낮음" 경고 후 진행 여부 확인.
- **미분류 의심 span**: Step 4(리뷰)의 `unclassified_candidates`로 기록해 taxonomy 확장 후보로 남긴다.

## 부분 재실행

- "탐지가 너무 까다롭다" → `min_severity`를 S2 이상으로 상향.
- "특정 카테고리만 다시" → 해당 카테고리만 재스캔.
