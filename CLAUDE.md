# Humanize KR — AI 한글 티 제거 하네스

## 프로젝트 개요

한국어 텍스트의 번역투·영어 인용 과다·기계적 병렬·관용구·피동태 남용·접속사 남발·리듬 균일성·이모지/불릿 과다 등 10대 카테고리 40+ 문체 패턴을 탐지·분류하고, **의미·사실·수치·고유명사·인용을 보존하면서** 문체·리듬·표현을 자연스럽게 재작성하는 5인 파이프라인 하네스.

## 철칙

1. **의미 불변 (Fidelity First)** — 사실·주장·수치·고유명사·인용은 100% 원문 보존.
2. **근거 기반 (Span-Grounded)** — 모든 변경은 탐지 finding에 연결. 탐지 없는 구간은 건드리지 않음.
3. **장르 유지 (Tone Match)** — 칼럼을 문학으로, 리포트를 에세이로 옮기지 않음.
4. **과윤문 금지 (No Over-Polish)** — 변경률 30% 초과 시 경고, 50% 초과 시 강제 중단.

## 디렉토리 구조

```
im-not-ai/                          # = Claude Code Plugin 루트
├── CLAUDE.md                       # 본 파일 — 프로젝트 가이드
├── .claude-plugin/
│   └── plugin.json                 # Plugin 매니페스트 (claude /plugin install 용)
├── agents/                         # ← 정본 (Plugin spec 표준 위치)
│   ├── korean-ai-tell-taxonomist.md
│   ├── ai-tell-detector.md
│   ├── korean-style-rewriter.md
│   ├── content-fidelity-auditor.md
│   ├── naturalness-reviewer.md
│   └── humanize-web-architect.md
├── skills/humanize-korean/         # ← 정본
│   ├── SKILL.md                    # 오케스트레이터
│   └── references/
│       ├── ai-tell-taxonomy.md     # SSOT — 10대분류 × 40+ 패턴
│       ├── rewriting-playbook.md   # 카테고리별 치환 레시피
│       └── web-service-spec.md     # Phase 5 웹 확장용
├── commands/                       # ← 정본 (슬래시 커맨드 6개)
│   ├── humanize.md
│   ├── humanize-detect.md
│   ├── humanize-redo.md
│   ├── humanize-status.md
│   ├── humanize-list.md
│   └── humanize-web.md
├── .claude/                        # 이 리포 안에서 직접 `claude` 켤 때를 위한 미러
│   ├── agents/                     # 루트 agents/ 미러
│   ├── skills/                     # 루트 skills/ 미러
│   └── commands/                   # 루트 commands/ 미러
├── scripts/
│   ├── install.sh                  # `.claude/`에 복사하는 비-Plugin 설치기
│   └── build-claude-ai-zip.sh      # Claude.ai 업로드용 .zip 빌드 (2.0)
├── dist/claude-ai/humanize-korean/ # Claude.ai 커스텀 스킬 (평탄화 변형, 2.0)
│   ├── SKILL.md                    # 4단계 순차 단일 스킬 (서브에이전트 없음)
│   └── references/
│       ├── detection-guide.md      # 탐지기 노하우 흡수
│       ├── audit-checklist.md      # 내용 감사 13항 흡수
│       ├── review-rubric.md        # 자연스러움 등급·과윤문·루프 흡수
│       ├── ai-tell-taxonomy.md     # (빌드 시 SSOT에서 복사 — gitignore)
│       └── rewriting-playbook.md   # (빌드 시 SSOT에서 복사 — gitignore)
└── _workspace/                     # 런타임 산출물 (run_id별)
    └── {YYYY-MM-DD-NNN}/
        ├── 01_input.txt
        ├── 02_detection.json
        ├── 03_rewrite.md
        ├── 03_rewrite_diff.json
        ├── 04_fidelity_audit.json
        ├── 05_naturalness_review.json
        ├── final.md
        └── summary.md
```

**듀얼 레이아웃**: 정본은 루트(plugin spec), 동시에 `.claude/`에 미러 디렉터리를 둬 plugin 등록 없이 이 리포 안에서 `claude` 켜는 흐름도 그대로 유지.

**Claude.ai 변형 (2.0)**: Claude.ai 커스텀 스킬은 서브에이전트(`Agent`)·`TeamCreate` 병렬 팀·슬래시 커맨드를 지원하지 않는다. 따라서 5인 파이프라인을 단일 `SKILL.md`가 4단계(탐지→윤문→내용 감사→자연스러움 리뷰)를 순차 수행하도록 평탄화하고, 각 에이전트의 전문 지식을 `dist/claude-ai/humanize-korean/references/`로 흡수했다. SSOT reference는 `scripts/build-claude-ai-zip.sh`가 빌드 시점에 `skills/humanize-korean/references/`에서 복사한다. 품질 기준(철칙·심각도·등급)은 Claude Code 버전과 동일.

**Codex 변형 (2.1)**: Codex는 Claude 전용 `Agent`/`TeamCreate`를 전제로 하지 않는다. `skills/humanize-korean/SKILL.md`는 같은 역할을 메인 agent가 순차 실행하는 fallback을 포함하며, `scripts/install-codex.sh`로 `${CODEX_HOME:-$HOME/.codex}/skills/humanize-korean`에 설치한다.

## 파이프라인

```
입력 텍스트
    ↓
[ai-tell-detector] — 탐지 (span·category·severity·suggested_fix)
    ↓
[korean-style-rewriter] — 윤문 (finding 기반 수술적 수정)
    ↓
[병렬 팀]
    ├─ [content-fidelity-auditor] — 의미 동등성 감사 (13항)
    └─ [naturalness-reviewer]     — 잔존 + 과윤문 판정
    ↓
[오케스트레이터 종합 판정]
    ├─ accept → final.md + summary.md
    ├─ rewrite_round_2 → 윤문가 재호출 (최대 3회)
    ├─ rollback_and_rewrite → 문제 edit 롤백
    └─ hold_and_report → 사람 검토 권고
```

## 5인 핵심 팀 (+ 웹 아키텍트 확장)

1. **korean-ai-tell-taxonomist** — 분류 체계 SSOT 관리. 실전에서 발견된 미분류 패턴을 심사해 v1→v2 승격.
2. **ai-tell-detector** — 탐지기. span 단위 JSON 리포트 생성. 문서 레벨 패턴(리듬·구조)도 포함.
3. **korean-style-rewriter** — 윤문가. finding 기반 수술적 재작성. 변경률 모니터링.
4. **content-fidelity-auditor** — 내용 감사관. 13항 체크리스트로 의미 훼손 탐지 → 롤백 지시.
5. **naturalness-reviewer** — 자연스러움 리뷰어. 탐지기 재실행으로 잔존·과윤문 계측. 품질 등급 판정.
6. **humanize-web-architect** (확장용) — 웹 서비스 요청 시 Next.js 15 + Vercel 아키텍처 설계.

## 심각도 기준

- **S1 결정적**: 한 번만 나와도 AI라고 확신하게 되는 패턴. 무조건 제거.
- **S2 강함**: 1~2회 허용, 3회+ 반복 시 제거.
- **S3 약함**: 다른 패턴과 중첩될 때만 문제.

## 품질 등급

- **A**: S1 0건, S2 2건 이하, score 개선 70%+
- **B**: S1 0건, S2 4건 이하, score 개선 50%+
- **C**: S1 1~2건 또는 과윤문 시그널 2개 — 2차 윤문
- **D**: S1 3건 이상 또는 심각한 과윤문 — 사람 검토

## 사용 방법

1. 새 세션에서 오케스트레이터 스킬 트리거:
   ```
   이 AI 글 자연스럽게 윤문해줘:
   ```
   (텍스트 첨부)
2. 오케스트레이터가 run_id 생성하고 5단계 파이프라인 실행.
3. 결과 `final.md` + `summary.md` 반환.

## 주요 금기

- 수치·단위·날짜 변경 금지.
- 고유명사·제품명·모델명 변경 금지.
- 큰따옴표 인용문 내부 변경 금지.
- 법률 조문·학술 개념어 임의 치환 금지.
- 새로운 주장·사실·예시 추가 금지.
- 원문에 있던 정보 누락 금지.

## 확장 포인트

- **웹 서비스화**: `humanize-web-architect` 호출 → `_workspace/web/` 산출물 → 실제 구현 엔지니어(필요 시 신규 에이전트).
- **다국어 확장**: 일본어·중국어로 확장 시 언어별 taxonomy 분리 파일 추가.
- **장르 확장**: 현재 4장르(칼럼·리포트·블로그·공적). 학술 논문·법률 문서·제품 카피 추가 가능.

## 참고

- 분류 체계: `skills/humanize-korean/references/ai-tell-taxonomy.md` (또는 미러 `.claude/skills/humanize-korean/references/ai-tell-taxonomy.md`)
- 윤문 처방: `skills/humanize-korean/references/rewriting-playbook.md`
- 웹 스펙: `skills/humanize-korean/references/web-service-spec.md`
