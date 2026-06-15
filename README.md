<p align="center">
  <img src="assets/social-preview.png" alt="im-not-ai — 한국어 문체 자연화 스킬" width="820">
</p>

# Humanize KR — 한국어 문체 자연화 스킬

한국어 글의 번역투, 기계적 병렬, 과한 접속, 리듬 단조로움, 학술 문체 어긋남을 줄여 **의미·사실·수치·고유명사·인용을 보존하면서** 자연스럽게 윤문하는 Claude Code / Claude.ai / Codex 호환 스킬입니다.

번역투, 과도한 영어 병기, 기계적 병렬("첫째 · 둘째 · 셋째"), 막연한 관용구, 피동태 남용, 문두 접속사 반복, 이모지·불릿 남용 등 **10대 카테고리 × 40+ 서브 패턴**을 심각도(S1/S2/S3)로 분류해 스팬 단위로 진단한 뒤 윤문합니다. 논문·학술 문체 요청 시에는 서울대 김태형·이영성 교수 관련 공개 논문 PDF와 Harvard 교수들의 공개 working paper/PDF에서 추출한 일반 학술 문체 원칙을 참고합니다.

## 왜 한글 특화인가

영어권 자동 윤문기는 한국어에 약합니다. 한글 AI 글의 티는 대부분 **영어 번역투**에서 나옵니다.

- "AI 기술을 **통해** 효율을 높**일 수 있다**" → "AI로 효율을 높인다"
- "이에 **있어서** 중요한 **점은**" → "여기서 중요한 건"
- "~**에 의해** 생성된" → "~가 만든"
- "**결론적으로**, 이는 **시사하는 바가 크다**" → (삭제)

이 하네스는 그 한글 고유 패턴을 SSOT로 정리하고, 탐지·윤문·내용 감사·자연스러움 검증을 분리된 역할로 수행합니다. Claude Code에서는 subagent를 쓸 수 있고, Codex에서는 같은 역할을 순차 실행합니다.

## 4대 철칙

1. **의미 보존** — 사실 · 주장 · 수치 · 고유명사 · 직접 인용은 원문과 의미 동등하게 보존.
2. **근거 기반** — 탐지된 span에만 수술적 수정. 탐지 없는 구간은 건드리지 않음.
3. **장르 유지** — 칼럼을 문학으로, 리포트를 에세이로 옮기지 않음.
4. **과윤문 금지** — 변경률 30% 초과 시 경고, 50% 초과 시 강제 중단.

## 아키텍처

```
입력 텍스트
    ↓
[ai-tell-detector]        ── 탐지 (span · category · severity)
    ↓
[korean-style-rewriter]   ── finding 기반 수술적 윤문
    ↓
[병렬 검증 팀]
    ├─ [content-fidelity-auditor]  ── 13항 체크리스트로 의미 동등성 감사
    └─ [naturalness-reviewer]      ── 탐지 재실행으로 잔존·과윤문 판정
    ↓
[오케스트레이터 종합]
    ├─ accept              → final.md + summary.md
    ├─ rewrite_round_2     → 2차 윤문 (최대 3회)
    ├─ rollback_and_rewrite → 문제 edit 롤백
    └─ hold_and_report     → 사람 검토 권고
```

## 6인 에이전트

| 에이전트 | 역할 |
|---------|------|
| `korean-ai-tell-taxonomist` | 분류 체계(SSOT) 관리, 신규 패턴 심사 승격 |
| `ai-tell-detector` | span 단위 JSON 탐지 리포트 생성 |
| `korean-style-rewriter` | finding 기반 수술적 윤문, 변경률 모니터링 |
| `content-fidelity-auditor` | 의미 동등성 감사 (13항), 훼손 시 롤백 지시 |
| `naturalness-reviewer` | 잔존 AI 티 · 과윤문 · 자연도 판정, 품질 등급 A~D |
| `humanize-web-architect` | (옵션) Next.js 15 + Vercel 웹 서비스 확장 설계 |

## AI 티 분류 체계 (요약)

| ID | 대분류 | 대표 서브 패턴 |
|----|-------|---------------|
| A | 번역투 | "~를 통해", "~에 대해", "~에 있어서", 이중 피동 "~되어진다", "가지고 있다" |
| B | 영어 인용·용어 과다 | 과도한 괄호 병기, 번역 가능한 영어 그대로 |
| C | 구조적 AI 패턴 | 기계적 "첫째/둘째/셋째", 과도한 불릿·헤딩·이모지 |
| D | AI 특유 관용구 | "결론적으로", "시사하는 바가 크다", "주목할 만하다", "혁신적인" |
| E | 리듬 균일성 | 문장 길이 표준편차 낮음, 동일 종결어미 반복 |
| F | 수식·중복 | "매우", "정말", 동의어 이중 수식, "~적/~성/~화" 남발 |
| G | Hedging 남용 | "~할 수 있을 것으로 보인다" 다중 완곡 |
| H | 접속사 남발 | 문두 "또한/따라서/즉/나아가" 연속 |
| I | 형식명사 과다 | "것이다", "점", "수", "바", "~할 필요가 있다" |
| J | 시각 장식 남용 | 과도한 **볼드**, "따옴표", 대시(—) 남발 |

전체 40+ 서브 패턴과 처방: [`ai-tell-taxonomy.md`](.claude/skills/humanize-korean/references/ai-tell-taxonomy.md) · [`rewriting-playbook.md`](.claude/skills/humanize-korean/references/rewriting-playbook.md)

## 심각도 & 품질 등급

**심각도**
- **S1 결정적**: 한 번만 나와도 AI 확신. 무조건 제거.
- **S2 강함**: 1~2회 허용, 3회+ 반복 시 제거.
- **S3 약함**: 다른 패턴과 중첩될 때만 문제.

**품질 등급 (윤문 후)**
- **A**: S1 0건, S2 ≤2건, 점수 개선 70%+
- **B**: S1 0건, S2 ≤4건, 개선 50%+
- **C**: S1 1~2건 or 과윤문 시그널 2개 → 2차 윤문
- **D**: S1 3건+ or 심각한 과윤문 → 사람 검토

## 사용법 — 5분이면 따라합니다

### 0. 전제

[Claude Code](https://claude.com/claude-code)가 설치돼 있어야 합니다. Mac · Windows · Linux 모두 지원합니다.

설치 확인:
```bash
claude --version
```

> Claude Code는 터미널에서 Claude(Anthropic의 AI)와 대화하며 파일을 같이 편집하는 CLI입니다. 아래 5단계는 **Claude Code**용 사용법입니다.
>
> **다른 실행 환경에서 쓰고 싶다면?** Claude.ai에서는 업로드용 zip을 쓰고, Codex에서는 `scripts/install-codex.sh`로 전역 skill에 설치합니다. → [Codex에서 쓰기](#codex에서-쓰기) · [Claude.ai에서 쓰기](#claudeai에서-쓰기).

### 1. 리포 받기

```bash
git clone https://github.com/cameleonh/im-not-ai.git
cd im-not-ai
```

### 2. 이 폴더 안에서 Claude Code 켜기

```bash
claude
```

> **중요:** 꼭 `im-not-ai` 폴더 **안에서** 실행하세요. 다른 위치에서 켜면 이 리포의 스킬이 로드되지 않아 일반 Claude Code처럼 동작합니다 (`.claude/` 아래에 agents·commands·skills 미러가 들어 있습니다).
>
> **다른 프로젝트에 끌어다 쓰고 싶다면** 두 가지 길이 있습니다 — Claude Code Plugin (`/plugin install`) 또는 Bash 설치 스크립트. 자세한 건 [설치 섹션](#설치--내-프로젝트--글로벌에-끌어다-쓰기).

### 3. 다듬을 한글 글 붙여넣고 부탁하기

평소 말투 그대로 쓰면 됩니다:

```
이 AI 글 자연스럽게 윤문해줘:

[ChatGPT / Claude / Gemini 초안 여기에 붙여넣기]
```

아래 표현 중 아무거나 쓰면 스킬이 자동 발동합니다:
- "AI 티 없애줘"
- "GPT 문체 제거해줘"
- "사람이 쓴 것처럼 윤문해줘"
- "번역투 제거"
- "한글 AI 윤문"

명령어·슬래시·옵션 없이 **자연어 한 문장으로 충분합니다.**

### 4. 결과 확인

Claude Code가 이 순서로 처리합니다:

1. **탐지** — 어디가 어떤 AI 티인지 10대 카테고리 × 심각도로 정리
2. **윤문** — 내용·수치·고유명사·인용은 보존하고 문체·리듬만 수정
3. **검증** — 의미가 훼손됐는지 감사 + 다시 AI스럽지 않은지 재측정
4. **출력** — 윤문본, 주요 변경 diff, 품질 등급(A/B/C/D), 잔존 패턴

터미널에서 윤문본을 바로 받아볼 수 있고, 세부 산출물은 리포 안의 `_workspace/{실행날짜-번호}/`에 저장됩니다:

| 파일 | 내용 |
|------|------|
| `01_input.txt` | 원문 그대로 |
| `02_detection.json` | AI 티 탐지 리포트 (위치·종류·심각도) |
| `03_rewrite.md` | 윤문본 |
| `04_fidelity_audit.json` | 내용 훼손 감사 결과 |
| `05_naturalness_review.json` | 자연도 재측정 결과 |
| `summary.md` | 점수 변화·주요 변경·등급 요약 |

### 5. 결과가 맘에 안 들면

그대로 말씀하시면 됩니다. 재실행·수정 명령을 따로 외울 필요 없습니다:

- **"이 문단만 다시 윤문해줘"** — 해당 구간만 재시도
- **"번역투만 더 손봐줘"** (또는 "관용구만 다시") — 특정 카테고리만 재처리
- **"윤문 강도 낮춰줘"** — 보수적 윤문 (결정적 패턴만 제거)
- **"원문 톤을 더 살려줘"** — 변경률 상한을 낮춰 원문 유지
- **"2차 윤문해줘"** — 현재 결과를 한 번 더 다듬기

### 6. 다른 글로 또 돌리고 싶을 때

Claude Code 세션 안에서 새 글을 붙여넣고 똑같이 부탁하면 됩니다. 실행마다 새 `_workspace/{날짜-번호}/` 폴더가 만들어져 이전 결과와 섞이지 않습니다.

## 설치 — 내 프로젝트 / 글로벌에 끌어다 쓰기

두 가지 방식 중 편한 쪽을 고르세요.

### 방식 A — Claude Code Plugin (권장)

이 리포는 Claude Code 공식 Plugin 규격(`.claude-plugin/plugin.json` + `marketplace.json` + 루트 `agents/`·`skills/`·`commands/`)을 모두 갖춘 자체 marketplace입니다. 두 줄로 설치 끝.

```bash
# Claude Code 세션 안에서:
/plugin marketplace add cameleonh/im-not-ai          # GitHub repo 단축 문법
/plugin install humanize-korean@cameleonh-plugins    # plugin@marketplace
```

- **마켓플레이스 이름**: `cameleonh-plugins` (수정하려면 [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)의 `name` 필드만 변경)
- **플러그인 이름**: `humanize-korean` (네임스페이싱 — 다른 marketplace의 동명 plugin과 충돌하지 않음)
- **자동 업데이트**: Git 변경 시 `/plugin update` 로 갱신
- **팀 공유**: `.claude/settings.json` 에 한 줄로 marketplace 등록 명시 가능

로컬 개발 중인 plugin을 바로 테스트하려면 (이 리포를 클론한 상태에서):
```bash
cd ~/path/to/im-not-ai
claude --plugin-dir .
```

### 방식 B — Bash 설치 스크립트 (Plugin 안 쓰는 환경용)

대상 디렉토리의 `.claude/`에 직접 복사합니다. Plugin marketplace에 의존하지 않고, 이 리포를 fork·커스터마이징해 쓰는 사용자에게 적합합니다. 의존성 없는 Bash 스크립트입니다 (Mac/Linux/WSL).

```bash
# 1) 이 리포 클론
git clone https://github.com/cameleonh/im-not-ai.git
cd im-not-ai

# 2) 현재 작업 디렉토리(다른 프로젝트)로 이동 후 설치
cd ~/my-other-project
~/path/to/im-not-ai/scripts/install.sh

# 또는 한 줄로
~/path/to/im-not-ai/scripts/install.sh --target ~/my-other-project
```

### 자주 쓰는 옵션

| 명령 | 동작 |
|------|------|
| `install.sh` | 현재 디렉토리의 `.claude/`에 복사 |
| `install.sh --target <경로>` | 지정 디렉토리에 복사 |
| `install.sh --global` | `~/.claude/`에 글로벌 설치 (어느 프로젝트에서든 사용 가능) |
| `install.sh --mode symlink` | 복사 대신 심볼릭 링크 (이 리포가 업데이트되면 자동 반영) |
| `install.sh --components commands` | 슬래시 커맨드만 (에이전트·스킬 제외) |
| `install.sh --dry-run` | 실제로 쓰지 않고 무엇을 할지만 표시 |
| `install.sh --uninstall --target <경로>` | 이 도구로 설치된 것만 제거 |
| `install.sh --help` | 전체 도움말 |

### 안전장치

- **자동 백업** — 같은 이름 파일이 있으면 `*.bak.<타임스탬프>`로 백업 후 새로 깖. `--force` 시만 백업 없이 덮어씀.
- **매니페스트 추적** — `<대상>/.claude/.humanize-kr-installed`에 설치된 파일 목록을 기록. `--uninstall`은 이 목록만 지우므로 사용자가 수동으로 추가한 다른 에이전트/스킬은 안전.
- **자기 자신 설치 방지** — 소스와 대상이 같으면 거부.
- **부분 설치** — `--components agents` / `skills` / `commands` 조합 가능.

### 글로벌 vs 로컬, 어느 쪽?

- **로컬(기본)**: 이 프로젝트에서만 윤문기를 쓰고 싶을 때. 프로젝트별 격리됨.
- **글로벌(`--global`)**: 어느 디렉토리에서 `claude`를 켜도 윤문이 가능. 단, `~/.claude/`에 다른 자산이 있으면 충돌 위험 → 백업이 자동으로 잡히지만 충돌 메시지를 확인하세요.
- **심볼릭 링크(`--mode symlink`)**: 이 리포 폴더를 절대 옮기지 않을 때만 권장. 옮기면 링크가 깨집니다.

## Codex에서 쓰기

Codex는 Claude의 subagent·TeamCreate 도구를 전제로 하지 않습니다. 이 repo의 `skills/humanize-korean/SKILL.md`는 Codex에서 같은 역할을 **탐지 → 윤문 → 의미 감사 → 자연스러움 리뷰** 순서로 실행하도록 fallback 절차를 포함합니다.

전역 설치:

```bash
bash scripts/install-codex.sh --global
```

설치 위치는 기본적으로 `${CODEX_HOME:-$HOME/.codex}/skills/humanize-korean`입니다. 다른 경로에 설치하려면:

```bash
bash scripts/install-codex.sh --target ~/.codex
```

설치 전 확인:

```bash
bash scripts/install-codex.sh --global --dry-run
```

사용 예:

```text
$humanize-korean 이 논문 초록을 한국어 학술 문체로 다듬어줘. 의미와 수치는 유지해.
```

## Claude.ai에서 쓰기

**2.0 신규.** 터미널(Claude Code)이 아니라 웹 브라우저의 [Claude.ai](https://claude.ai)에서도 윤문기를 쓸 수 있습니다.

Claude.ai의 커스텀 스킬은 서브에이전트·슬래시 커맨드·병렬 팀을 지원하지 않습니다. 그래서 이 리포의 5인 멀티에이전트 파이프라인을 **한 스킬이 4단계(탐지 → 윤문 → 내용 감사 → 자연스러움 리뷰)를 순차로 수행하도록 평탄화**한 자족형 패키지를 따로 제공합니다. 품질 기준(의미 보존·근거 기반·과윤문 방지·등급 A/B/C/D)은 동일합니다.

### 전제

- Claude.ai **Pro · Max · Team · Enterprise** 플랜
- 설정에서 **코드 실행(Code execution)** 켜짐

### 1) 업로드용 .zip 만들기

이 리포를 클론한 폴더에서:

```bash
bash scripts/build-claude-ai-zip.sh
```

`dist/humanize-korean-claude-ai.zip`이 만들어집니다. 스크립트가 분류 체계·윤문 처방(SSOT)을 자동 복사·동기화하고, 스킬 이름·설명 제약(예약어·길이)을 검증한 뒤 압축합니다. 리포가 업데이트되면 다시 실행만 하면 됩니다.

> 직접 압축하지 말고 꼭 이 스크립트를 쓰세요. SSOT 파일 2개는 빌드 시점에 복사되므로(`dist/`에 상시 보관하지 않음), 수동 압축하면 분류 체계가 빠집니다.

### 2) Claude.ai에 등록

1. Claude.ai → **Settings → Features → Skills**
2. 위 `dist/humanize-korean-claude-ai.zip` 업로드

### 3) 사용

새 대화에서 평소처럼 부탁하면 됩니다 (Claude Code와 동일한 트리거):

```
이 AI 글 자연스럽게 윤문해줘:

[ChatGPT / Claude / Gemini 초안 여기에 붙여넣기]
```

윤문본 + 요약표(길이·변경률·카테고리 before/after·점수·등급) + 주요 변경 하이라이트를 대화 안에서 바로 받습니다. "2차 윤문해줘", "이 문단만", "윤문 강도 낮춰줘" 같은 후속 요청도 그대로 됩니다.

> **참고:** Claude.ai 커스텀 스킬은 기기·계정마다 따로 업로드해야 하며(조직 공유 불가), Claude Code 스킬과는 별개로 관리됩니다.

## 슬래시 커맨드 (정밀 제어용)

> **기여 표기:** 이 섹션의 6개 슬래시 커맨드([.claude/commands/](.claude/commands/))는 **Jaewoo Kim** 이 원저작자 동의 하에 추가한 것입니다. MIT 라이선스를 따릅니다.

자연어 트리거("AI 티 없애줘") 외에, 단계를 직접 제어하고 싶을 때 쓰는 6개 커맨드입니다. Claude Code에서 `/`만 누르면 자동완성됩니다.

| 커맨드 | 용도 | 예시 |
|--------|------|------|
| [`/humanize`](.claude/commands/humanize.md) | 풀 파이프라인 (탐지 → 윤문 → 검증) | `/humanize [텍스트 또는 파일경로]` |
| [`/humanize-detect`](.claude/commands/humanize-detect.md) | 탐지만 (윤문 X) — 어디가 AI 티인지 진단 | `/humanize-detect [텍스트]` |
| [`/humanize-redo`](.claude/commands/humanize-redo.md) | 가장 최근 결과 2차 윤문·부분 재실행 | `/humanize-redo 번역투만 다시` |
| [`/humanize-status`](.claude/commands/humanize-status.md) | 최근(또는 지정) run 결과 다시 보기 | `/humanize-status 2026-04-25-001` |
| [`/humanize-list`](.claude/commands/humanize-list.md) | 과거 실행 목록을 표로 비교 | `/humanize-list 10` |
| [`/humanize-web`](.claude/commands/humanize-web.md) | 웹 서비스(Next.js+Vercel) 설계 문서 생성 | `/humanize-web 익명 MVP만` |

**언제 슬래시를, 언제 자연어를 쓸까**
- 그냥 윤문하고 싶다 → 자연어 한 문장이 가장 빠릅니다.
- "탐지만 해줘", "강도 낮춰서", "이전 결과만 다시 보고 싶다" 같은 **단계·옵션 제어**가 필요할 때 슬래시 커맨드를 쓰세요.

## Do-NOT List (탐지·윤문 대상 제외)

- 수치 · 단위 · 날짜
- 고유명사 · 인명 · 제품명 · 모델명
- 큰따옴표 내부 직접 인용
- 법률 · 규정 조문
- 학술 개념어 (불가피한 경우)

## 학술 문체 참고자료

논문·학술 문체 요청 시 `skills/humanize-korean/references/academic-style-sources.md`를 참고합니다. 여기에는 서울대 김태형·이영성 교수 관련 공개 PDF, Harvard의 Claudia Goldin·Dani Rodrik·Cass Sunstein·Steven Pinker 공개 PDF/working paper 링크와, 그 자료에서 추출한 일반 학술 문체 원칙이 들어 있습니다.

PDF 원문은 repo에 포함하지 않습니다. 로컬에서만 받아 참고하려면:

```bash
bash scripts/fetch-style-pdfs.sh --dry-run
bash scripts/fetch-style-pdfs.sh
```

다운로드 위치는 gitignore된 `_style_sources/pdf/`입니다.

## 웹 서비스 확장 (옵션)

`humanize-web-architect` 에이전트가 Next.js 15 App Router + Vercel Fluid Compute + AI Gateway 기반 웹앱 설계를 담당한다. UX는 4화면(입력 → 탐지 하이라이트 → 좌우 diff → 윤문본 복사). 상세: [`web-service-spec.md`](.claude/skills/humanize-korean/references/web-service-spec.md).

로드맵: v0 MVP(익명·단일 호출) → v1(로그인·히스토리) → v2(Pro/Team · API · 웹훅) → v3(Chrome Extension) → v4(일본어·중국어 확장).

## 라이선스 & 윤리

- 본 도구는 AI 탐지기 우회가 아니라 **한글 글쓰기 품질 개선**을 목적으로 합니다.
- 학술 제출·저널리즘 진실성 보증 도구가 아닙니다
- 분류 체계(`ai-tell-taxonomy.md`)는 연구·교육 목적 자유 이용 가능합니다.

## 기여

새로운 AI 티 패턴을 발견했다면 `references/ai-tell-taxonomy.md` 하단 버전 섹션에 후보로 제안해 주세요. 실증 사례 2건 이상을 첨부하면 분류학자 에이전트가 v1 → v2 승격시킵니다.

---

Built with [Claude Code](https://claude.com/claude-code) + https://github.com/revfactory/harness 하네스 아키텍처 기반 프로젝트.
