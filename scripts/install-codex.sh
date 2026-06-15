#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_SKILL="$SOURCE_ROOT/skills/humanize-korean"

TARGET=""
GLOBAL=0
MODE="copy"
DRY_RUN=0
FORCE=0
UNINSTALL=0

log() { printf "[*] %s\n" "$*"; }
ok() { printf "[OK] %s\n" "$*"; }
err() { printf "[X] %s\n" "$*" >&2; }

usage() {
  cat <<'EOF'
Humanize Korean Codex installer

Usage:
  install-codex.sh [options]

Options:
  --global              Install to ${CODEX_HOME:-$HOME/.codex}/skills
  --target <path>       Install to <path>/skills
  --mode <copy|symlink> Copy or symlink the skill
  --dry-run             Show planned actions only
  --force               Replace existing install without backup
  --uninstall           Remove files installed by this script
  -h, --help            Show help

Examples:
  ./scripts/install-codex.sh --global
  ./scripts/install-codex.sh --target ~/.codex
  ./scripts/install-codex.sh --target ./dist/codex --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global) GLOBAL=1; shift;;
    --target) TARGET="${2:?--target requires a path}"; shift 2;;
    --mode) MODE="${2:?--mode requires copy or symlink}"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --force) FORCE=1; shift;;
    --uninstall) UNINSTALL=1; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown option: $1"; usage; exit 1;;
  esac
done

if [[ "$MODE" != "copy" && "$MODE" != "symlink" ]]; then
  err "--mode must be copy or symlink"
  exit 1
fi

if [[ ! -d "$SOURCE_SKILL" ]]; then
  err "Missing source skill: $SOURCE_SKILL"
  exit 1
fi

if [[ $GLOBAL -eq 1 ]]; then
  CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"
elif [[ -n "$TARGET" ]]; then
  CODEX_ROOT="$TARGET"
else
  CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"
fi

DEST_ROOT="$CODEX_ROOT/skills"
DEST_SKILL="$DEST_ROOT/humanize-korean"
MANIFEST="$DEST_ROOT/.humanize-korean-codex-installed"

log "Source: $SOURCE_SKILL"
log "Target: $DEST_SKILL"
log "Mode: $MODE / dry-run: $DRY_RUN / force: $FORCE / uninstall: $UNINSTALL"

if [[ $UNINSTALL -eq 1 ]]; then
  if [[ ! -f "$MANIFEST" ]]; then
    err "No manifest found: $MANIFEST"
    exit 1
  fi
  if [[ $DRY_RUN -eq 0 ]]; then
    while IFS= read -r path; do
      [[ -n "$path" ]] && rm -rf "$path"
    done < "$MANIFEST"
    rm -f "$MANIFEST"
  fi
  ok "Uninstalled"
  exit 0
fi

if [[ -e "$DEST_SKILL" || -L "$DEST_SKILL" ]]; then
  if [[ $FORCE -eq 1 ]]; then
    log "Removing existing install"
    [[ $DRY_RUN -eq 1 ]] || rm -rf "$DEST_SKILL"
  else
    backup="${DEST_SKILL}.bak.$(date +%Y%m%d-%H%M%S)"
    log "Backing up existing install to $backup"
    [[ $DRY_RUN -eq 1 ]] || mv "$DEST_SKILL" "$backup"
  fi
fi

if [[ $DRY_RUN -eq 0 ]]; then
  mkdir -p "$DEST_ROOT"
fi

if [[ "$MODE" == "symlink" ]]; then
  log "Linking skill"
  [[ $DRY_RUN -eq 1 ]] || ln -s "$SOURCE_SKILL" "$DEST_SKILL"
else
  log "Copying skill"
  [[ $DRY_RUN -eq 1 ]] || cp -R "$SOURCE_SKILL" "$DEST_SKILL"
fi

if [[ $DRY_RUN -eq 0 ]]; then
  printf "%s\n" "$DEST_SKILL" > "$MANIFEST"
fi

ok "Installed for Codex"
log 'Use in Codex with: $humanize-korean'
