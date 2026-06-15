#!/usr/bin/env bash
# Humanize KR — Claude Code 프로젝트 자동 설치기
# 에이전트·스킬·슬래시 커맨드를 대상 디렉토리의 .claude/ 에 복사(또는 심볼릭 링크)한다.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# 정본은 리포 루트(plugin spec)이며, 대상의 .claude/ 로 매핑 복사한다.
SOURCE_AGENTS="$SOURCE_ROOT/agents"
SOURCE_SKILLS="$SOURCE_ROOT/skills"
SOURCE_COMMANDS="$SOURCE_ROOT/commands"

if [[ -t 1 ]]; then
  C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YEL=$'\033[1;33m'; C_BLU=$'\033[0;34m'; C_RST=$'\033[0m'
else
  C_RED=''; C_GRN=''; C_YEL=''; C_BLU=''; C_RST=''
fi

log()  { printf "%s[*]%s %s\n" "$C_BLU" "$C_RST" "$*"; }
ok()   { printf "%s[OK]%s %s\n" "$C_GRN" "$C_RST" "$*"; }
warn() { printf "%s[!]%s %s\n" "$C_YEL" "$C_RST" "$*"; }
err()  { printf "%s[X]%s %s\n" "$C_RED" "$C_RST" "$*" >&2; }

TARGET=""
GLOBAL=0
MODE="copy"
COMPONENTS="agents,skills,commands"
DRY_RUN=0
FORCE=0
UNINSTALL=0

usage() {
  cat <<'EOF'
Humanize KR 설치기

사용법:
  install.sh [옵션]

옵션:
  --target <경로>         대상 프로젝트 디렉토리 (기본: 현재 디렉토리)
  --global                ~/.claude 에 글로벌 설치 (--target 무시)
  --mode <copy|symlink>   복사 또는 심볼릭 링크 (기본: copy)
                          symlink 모드는 소스가 항상 같은 위치에 있어야 동작.
  --components <목록>     쉼표 구분 — agents,skills,commands (기본: 전체)
  --dry-run               실제로 쓰지 않고 무엇을 할지만 표시
  --force                 기존 파일을 백업 없이 덮어씀
  --uninstall             이 도구로 설치된 자산만 제거
  -h, --help              이 도움말

예시:
  ./install.sh                              # 현재 디렉토리에 설치
  ./install.sh --target ~/my-project        # 특정 프로젝트에 설치
  ./install.sh --global                     # 글로벌(~/.claude) 설치
  ./install.sh --mode symlink               # 심볼릭 링크 (소스 변경 자동 반영)
  ./install.sh --components commands        # 슬래시 커맨드만
  ./install.sh --dry-run                    # 시뮬레이션
  ./install.sh --uninstall --target ~/foo   # 제거
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:?--target 에 경로가 필요합니다}"; shift 2;;
    --global) GLOBAL=1; shift;;
    --mode) MODE="${2:?--mode 에 copy 또는 symlink 가 필요합니다}"; shift 2;;
    --components) COMPONENTS="${2:?--components 에 목록이 필요합니다}"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --force) FORCE=1; shift;;
    --uninstall) UNINSTALL=1; shift;;
    -h|--help) usage; exit 0;;
    *) err "알 수 없는 옵션: $1"; usage; exit 1;;
  esac
done

if [[ "$MODE" != "copy" && "$MODE" != "symlink" ]]; then
  err "--mode 는 copy 또는 symlink 만 가능합니다 (입력값: $MODE)"
  exit 1
fi

if [[ ! -d "$SOURCE_AGENTS" || ! -d "$SOURCE_SKILLS" || ! -d "$SOURCE_COMMANDS" ]]; then
  err "소스 자산을 찾을 수 없습니다 (루트의 agents/ skills/ commands/ 중 일부 누락):"
  err "  $SOURCE_AGENTS"
  err "  $SOURCE_SKILLS"
  err "  $SOURCE_COMMANDS"
  err "이 스크립트는 im-not-ai 리포 안의 scripts/ 에서 실행되어야 합니다."
  exit 1
fi

if [[ $GLOBAL -eq 1 ]]; then
  DEST_CLAUDE="$HOME/.claude"
  DEST_LABEL="$HOME/.claude (글로벌)"
else
  TARGET="${TARGET:-$(pwd)}"
  if [[ ! -d "$TARGET" ]]; then
    err "대상 디렉토리가 없습니다: $TARGET"
    exit 1
  fi
  TARGET="$(cd "$TARGET" && pwd)"
  DEST_CLAUDE="$TARGET/.claude"
  DEST_LABEL="$TARGET/.claude"
fi

if [[ -d "$DEST_CLAUDE" ]]; then
  RESOLVED_DEST="$(cd "$DEST_CLAUDE" && pwd)"
  if [[ "$RESOLVED_DEST" == "$SOURCE_ROOT/.claude" ]]; then
    err "소스 리포 자체에 설치하려 합니다. 이 리포는 이미 .claude/ 미러를 갖고 있습니다: $DEST_CLAUDE"
    err "다른 디렉토리(--target)나 --global 을 사용하세요."
    exit 1
  fi
fi

HAS_AGENTS=0; HAS_SKILLS=0; HAS_COMMANDS=0
IFS=',' read -ra _COMP_ARR <<<"$COMPONENTS"
for c in "${_COMP_ARR[@]}"; do
  case "$c" in
    agents)   HAS_AGENTS=1;;
    skills)   HAS_SKILLS=1;;
    commands) HAS_COMMANDS=1;;
    "") ;;
    *) err "알 수 없는 컴포넌트: $c (가능: agents, skills, commands)"; exit 1;;
  esac
done

MANIFEST="$DEST_CLAUDE/.humanize-kr-installed"

log "소스 : $SOURCE_ROOT (정본: agents/, skills/, commands/)"
log "대상 : $DEST_LABEL"
log "모드 : $MODE / 컴포넌트 : $COMPONENTS / dry-run : $DRY_RUN / force : $FORCE / uninstall : $UNINSTALL"

run_uninstall() {
  if [[ ! -f "$MANIFEST" ]]; then
    err "이 도구로 설치된 매니페스트가 없습니다: $MANIFEST"
    err "수동 제거 또는 이미 제거된 상태일 수 있습니다."
    exit 1
  fi
  log "제거 시작..."
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ -e "$path" || -L "$path" ]]; then
      log "rm -rf $path"
      if [[ $DRY_RUN -eq 0 ]]; then rm -rf "$path"; fi
    fi
  done < "$MANIFEST"
  if [[ $DRY_RUN -eq 0 ]]; then
    rm -f "$MANIFEST"
    rmdir "$DEST_CLAUDE/agents" 2>/dev/null || true
    rmdir "$DEST_CLAUDE/commands" 2>/dev/null || true
    rmdir "$DEST_CLAUDE/skills" 2>/dev/null || true
    rmdir "$DEST_CLAUDE" 2>/dev/null || true
  fi
  ok "제거 완료"
}

if [[ $UNINSTALL -eq 1 ]]; then
  run_uninstall
  exit 0
fi

place_one() {
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    warn "소스 없음 (스킵): $src"
    return
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      log "기존 제거 (force): $dst"
      if [[ $DRY_RUN -eq 0 ]]; then rm -rf "$dst"; fi
    else
      local backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
      warn "기존 백업: $dst -> $(basename "$backup")"
      if [[ $DRY_RUN -eq 0 ]]; then mv "$dst" "$backup"; fi
    fi
  fi

  if [[ $DRY_RUN -eq 0 ]]; then mkdir -p "$(dirname "$dst")"; fi

  if [[ "$MODE" == "symlink" ]]; then
    log "link  $(basename "$src") -> $dst"
    if [[ $DRY_RUN -eq 0 ]]; then ln -s "$src" "$dst"; fi
  else
    log "copy  $(basename "$src") -> $dst"
    if [[ $DRY_RUN -eq 0 ]]; then cp -R "$src" "$dst"; fi
  fi

  if [[ $DRY_RUN -eq 0 ]]; then printf "%s\n" "$dst" >> "$MANIFEST"; fi
  return 0
}

if [[ $DRY_RUN -eq 0 ]]; then
  mkdir -p "$DEST_CLAUDE"
  if [[ -f "$MANIFEST" ]]; then
    mv "$MANIFEST" "${MANIFEST}.prev.$(date +%Y%m%d-%H%M%S)"
  fi
  : > "$MANIFEST"
fi

if [[ $HAS_AGENTS -eq 1 ]]; then
  log "에이전트 설치 중..."
  shopt -s nullglob
  for f in "$SOURCE_AGENTS"/*.md; do
    place_one "$f" "$DEST_CLAUDE/agents/$(basename "$f")"
  done
  shopt -u nullglob
fi

if [[ $HAS_SKILLS -eq 1 ]]; then
  log "스킬 설치 중..."
  place_one "$SOURCE_SKILLS/humanize-korean" "$DEST_CLAUDE/skills/humanize-korean"
fi

if [[ $HAS_COMMANDS -eq 1 ]]; then
  log "슬래시 커맨드 설치 중..."
  shopt -s nullglob
  for f in "$SOURCE_COMMANDS"/*.md; do
    place_one "$f" "$DEST_CLAUDE/commands/$(basename "$f")"
  done
  shopt -u nullglob
fi

if [[ $DRY_RUN -eq 0 ]]; then
  printf "%s\n" "$MANIFEST" >> "$MANIFEST"
fi

ok "설치 완료 → $DEST_LABEL"
if [[ $GLOBAL -eq 1 ]]; then
  log "확인: 어느 디렉토리에서든 'claude' 실행 후 /humanize 또는 '한국어 문체 다듬어줘'"
else
  log "확인: cd \"$TARGET\" && claude  → 그 안에서 /humanize 또는 '한국어 문체 다듬어줘'"
fi
log "제거: $0 --uninstall$([[ $GLOBAL -eq 1 ]] && echo ' --global' || echo " --target \"$TARGET\"")"
