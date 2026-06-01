#!/usr/bin/env bash
#
# build-claude-ai-zip.sh
# ----------------------
# Humanize KR 2.0 — Claude.ai Custom Skill 업로드용 .zip 빌드 스크립트.
#
# 하는 일:
#   1. SSOT references 2개(ai-tell-taxonomy.md, rewriting-playbook.md)를
#      skills/humanize-korean/references/ 에서 dist 패키지로 복사 동기화.
#   2. SKILL.md frontmatter 제약 검증 (name 예약어 / description 길이 / 필수 파일).
#   3. dist/humanize-korean-claude-ai.zip 생성 (zip 루트에 humanize-korean/ 폴더).
#   4. 업로드 안내 출력.
#
# 사용법:  bash scripts/build-claude-ai-zip.sh
#
set -euo pipefail

# --- 경로 ---------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PKG_DIR="$ROOT_DIR/dist/claude-ai/humanize-korean"      # self-contained 스킬 폴더
REF_DIR="$PKG_DIR/references"
SSOT_DIR="$ROOT_DIR/skills/humanize-korean/references"  # SSOT 원본
ZIP_OUT="$ROOT_DIR/dist/humanize-korean-claude-ai.zip"

SKILL_MD="$PKG_DIR/SKILL.md"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

echo "▶ Humanize KR — Claude.ai 스킬 빌드"
echo ""

# --- 0. 사전 점검 -------------------------------------------------------
[ -f "$SKILL_MD" ] || fail "SKILL.md 없음: $SKILL_MD"
[ -d "$REF_DIR" ]  || fail "references 폴더 없음: $REF_DIR"
command -v zip >/dev/null 2>&1 || fail "'zip' 명령이 필요합니다 (macOS/Linux 기본 제공)."

# --- 1. SSOT 복사 동기화 ------------------------------------------------
echo "1) SSOT references 동기화"
for f in ai-tell-taxonomy.md rewriting-playbook.md; do
  src="$SSOT_DIR/$f"
  [ -f "$src" ] || fail "SSOT 원본 없음: $src"
  cp "$src" "$REF_DIR/$f"
  ok "복사: references/$f"
done
echo ""

# --- 2. frontmatter 검증 ------------------------------------------------
echo "2) SKILL.md frontmatter 검증"

# name: 둘째 줄부터 frontmatter. 'name:' 라인 추출.
name_line="$(grep -m1 '^name:' "$SKILL_MD" | sed 's/^name:[[:space:]]*//')"
[ -n "$name_line" ] || fail "frontmatter에 name 필드가 없습니다."
# 예약어 / 길이 / 문자 규칙
case "$name_line" in
  *claude*|*anthropic*) fail "name '$name_line' 에 예약어(claude/anthropic) 포함 — Claude.ai가 거부합니다." ;;
esac
if [ "${#name_line}" -gt 64 ]; then fail "name 길이 ${#name_line}자 > 64자 제한."; fi
if ! printf '%s' "$name_line" | grep -Eq '^[a-z0-9-]+$'; then
  fail "name '$name_line' 은 소문자·숫자·하이픈만 허용됩니다."
fi
ok "name: $name_line (예약어 없음, ${#name_line}자)"

# description: 길이 검증 (한 줄 가정). 글자 수(문자) 기준.
desc_line="$(grep -m1 '^description:' "$SKILL_MD" | sed 's/^description:[[:space:]]*//')"
[ -n "$desc_line" ] || fail "frontmatter에 description 필드가 없습니다."
desc_len="$(printf '%s' "$desc_line" | wc -m | tr -d ' ')"
if [ "$desc_len" -gt 1024 ]; then fail "description ${desc_len}자 > 1024자 제한."; fi
ok "description: ${desc_len}자 (≤1024)"
echo ""

# --- 3. zip 생성 --------------------------------------------------------
echo "3) zip 생성"
rm -f "$ZIP_OUT"
# zip 루트에 'humanize-korean/' 폴더가 오도록 dist/claude-ai 에서 압축.
( cd "$ROOT_DIR/dist/claude-ai" && zip -rq "$ZIP_OUT" humanize-korean \
    -x '*.DS_Store' )
[ -f "$ZIP_OUT" ] || fail "zip 생성 실패."
ok "생성: ${ZIP_OUT#$ROOT_DIR/}"
echo ""

# --- 4. 결과 요약 -------------------------------------------------------
echo "▶ 빌드 완료. 패키지 내용:"
unzip -l "$ZIP_OUT" | sed 's/^/  /'
echo ""
echo "▶ 업로드 방법 (Claude.ai)"
echo "  1. Pro/Max/Team/Enterprise 플랜 + '코드 실행' 켜짐 확인"
echo "  2. Settings → Features → Skills"
echo "  3. '$ZIP_OUT' 업로드"
echo "  4. 새 대화에서:  이 AI 글 자연스럽게 윤문해줘:  (텍스트 첨부)"
