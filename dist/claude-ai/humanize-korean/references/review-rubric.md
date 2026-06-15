# 자연스러움 리뷰 루브릭 (Naturalness Review)

Step 4(리뷰)의 기준. 윤문본의 최종 심판관 역할. "이 글이 한국어 독자에게 자연스럽게 읽히는가?"와 "부자연스럽게 과윤문되지 않았는가?"만 묻는다. 내용 무결성은 Step 3(감사)이 본다.

## 평가 3축

### 축 1 — AI 티 잔존 (재탐지)

윤문본을 Step 1 방식으로 다시 스캔한다.

- 재스캔 finding 수, `category_summary`, `severity_weighted_score`를 원본과 비교.
- **합격선**: S1 잔존 0건 + S2 3건 이하 + weighted_score 원본 대비 70% 이상 하락.

### 축 2 — 과윤문 (Over-polish) 5신호

다음 중 **2개 이상 동시 발견** 시 과윤문 플래그.

1. **장르 이탈**: 리포트가 에세이 톤으로 전환 (피동·명사형 서술 급감, 형식성 붕괴).
2. **문학화**: 원문에 없던 비유·수사가 추가됨.
3. **구어화 과다**: 격식체가 "~해요"·"~네요"로 전환 (원문이 구어가 아닌 한).
4. **리듬 과조작**: 모든 문장이 짧아져 숨가쁘거나, 장문이 과도하게 섞여 난해.
5. **어휘 대체 과다**: 원문 핵심어(키워드)가 다른 어휘로 바뀌어 주제 추적이 끊김.

### 축 3 — 한국어 자연도 (질적)

- 조사·어미가 자연스러운가.
- 문단 간 논리 흐름이 끊기지 않는가.
- 읽을 때 걸리는 지점(어색한 어순·불필요한 쉼표·비문)이 없는가.

## 판정 매트릭스

| 잔존 | 과윤문 | 판정 | 후속 |
|------|--------|------|------|
| 없음 | 없음 | `accept` | 최종 출력 승인 |
| S2 3건 이하 | 없음 | `accept_with_note` | 출력하되 잔존 기록 |
| S1 잔존 OR S2 4건+ | 없음 | `rewrite_round_2` | 해당 finding 범위만 Step 2 재실행 |
| 어떠함 | 과윤문 | `rollback_and_rewrite` | 문제 edit 롤백 후 Step 2 재실행 |
| S1 3건+ AND 과윤문 | - | `hold_and_report` | 사람 개입 요청 |

## 품질 등급

- **A**: S1 0건, S2 2건 이하, 과윤문 0신호, score 개선 70%+.
- **B**: S1 0건, S2 4건 이하, 과윤문 1신호 이하, score 개선 50%+.
- **C**: S1 1~2건 또는 과윤문 2신호 — 2차 윤문 필요.
- **D**: S1 3건 이상 또는 심각한 과윤문 — 사람 검토.

## 출력 예시

```json
{
  "meta": {
    "score_before": 71.5,
    "score_after": 18.2,
    "score_improvement": 53.3,
    "s1_residual": 0,
    "s2_residual": 2,
    "over_polish_signals": [],
    "verdict": "accept",
    "quality_level": "A"
  },
  "residual_findings": [
    {
      "category": "H-1",
      "severity": "S2",
      "text_span": "또한 이는",
      "reason": "문두 '또한'이 2개 남았으나 문서 전체 밀도는 낮아 허용 범위",
      "action": "none"
    }
  ],
  "over_polish_findings": [],
  "unclassified_candidates": [
    {
      "text_span": "~의 결을 드러낸다",
      "frequency": 3,
      "reason": "원문에 없던 표현이 윤문에서 반복 생성 — AI 윤문 특유 어휘 가능성",
      "escalation": "taxonomy_review"
    }
  ],
  "next_action": { "type": "accept", "targets": [] }
}
```

## 반복 루프 정책

- **최대 3회.** 2차는 S1 잔존 또는 S2 4건+ 일 때 해당 target finding만 재처리.
- 3회 후에도 C 등급 이하면 `next_action.type = "hold_and_report"`로 강제하고 최종 리포트에 "사람 검토 권고"를 단다.
- 미분류 의심 패턴(`unclassified_candidates`)은 taxonomy 확장 후보로 기록해 둔다. 실증 사례 2건 이상이면 `ai-tell-taxonomy.md`의 버전 섹션에 후보로 제안.
