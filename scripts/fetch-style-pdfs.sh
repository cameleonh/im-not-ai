#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$ROOT_DIR/_style_sources/pdf"
DRY_RUN=0
LIST_ONLY=0

usage() {
  cat <<'EOF'
Fetch public academic-style PDF sources for local reference.

Usage:
  fetch-style-pdfs.sh [options]

Options:
  --output <dir>   Output directory
  --dry-run        Show planned downloads only
  --list           Print source list only
  -h, --help       Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT_DIR="${2:?--output requires a directory}"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --list) LIST_ONLY=1; shift;;
    -h|--help) usage; exit 0;;
    *) printf "[X] Unknown option: %s\n" "$1" >&2; usage; exit 1;;
  esac
done

sources=(
  "KR-GIM-1|kpaj-39886-gim-shrinking-city.pdf|https://kpaj.or.kr/xml/39886/39886.pdf"
  "KR-LEE-1|kpaj-03318-lee-regional-decline-health.pdf|https://www.kpaj.or.kr/xml/03318/03318.pdf"
  "KR-LEE-2|kpaj-21770-lee-urban-renewal-sam.pdf|https://www.kpaj.or.kr/xml/21770/21770.pdf"
  "KR-LEE-3|kpaj-08476-lee-software-regional-innovation.pdf|https://www.kpaj.or.kr/xml/08476/08476.pdf"
  "EN-GOLDIN-1|nber-w33311-goldin-babies-macroeconomy.pdf|https://www.nber.org/system/files/working_papers/w33311/w33311.pdf"
  "EN-RODRIK-1|nber-w9129-rodrik-feasible-globalizations.pdf|https://www.nber.org/system/files/working_papers/w9129/w9129.pdf"
  "EN-SUNSTEIN-1|sunstein-ethics-of-nudging.pdf|https://laweconcenter.law.harvard.edu/wp-content/uploads/2024/11/Sunstein_806.pdf"
  "EN-PINKER-1|dash-pinker-common-knowledge.pdf|https://dash.harvard.edu/bitstreams/7312037d-7a26-6bd4-e053-0100007fdf3b/download"
)

for item in "${sources[@]}"; do
  IFS='|' read -r id file url <<<"$item"
  if [[ $LIST_ONLY -eq 1 ]]; then
    printf "%s %s %s\n" "$id" "$file" "$url"
    continue
  fi
  dest="$OUT_DIR/$file"
  printf "[*] %s -> %s\n" "$id" "$dest"
  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$OUT_DIR"
    curl -L --fail --retry 2 --retry-delay 1 -o "$dest" "$url"
  fi
done

if [[ $LIST_ONLY -eq 0 ]]; then
  printf "[OK] PDF sources ready: %s\n" "$OUT_DIR"
fi
