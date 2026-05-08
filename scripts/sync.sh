#!/usr/bin/env bash
# Main entry. Orchestrates both v1 (incremental) and v2 (full chapter) pipelines.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/common.sh"

MODE="full"            # full-sync (v1 default) | dry-run | only-detect | init | commit-sync | full-gen | list-chapters | regen-index | regen-sidebar | estimate | emit-llms-txt
FROM_SHA=""
TO_SHA=""
ONLY_MAPPING=""
INIT_SHA=""
CHAPTER=""
DOC_FILTER=""
FORCE=""

usage() {
    cat <<EOF
Usage: $0 [v1 flags] [v2 flags]

v1 flags (incremental-patch pipeline):
  --dry-run                     detect+prepare only
  --only-detect                 detect only
  --mapping <id>                restrict to one mapping
  --from <sha> --to <sha>       override commit range
  --init <sha>                  set last_sync.json baseline
  --commit-sync                 bump last_sync.json to current changes.json's to_sha

v2 flags (full chapter generation):
  --full --chapter <name>       generate a whole chapter
  --doc <slug>                  (with --full) restrict to one doc
  --force-regenerate            (with --full) ignore signatures
  --estimate                    print cost/token estimate, no API calls
  --list-chapters               print configured chapters
  --regenerate-index            (with --chapter) regenerate index.md only
  --regenerate-sidebar          (with --chapter) regenerate sidebar fragment only
  --emit-llms-txt               (re)generate docs/public/llms*.txt
EOF
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        # v1 flags
        --dry-run)            MODE="dry-run"; shift ;;
        --only-detect)        MODE="only-detect"; shift ;;
        --mapping)            ONLY_MAPPING="${2:-}"; shift 2 ;;
        --from)               FROM_SHA="${2:-}"; shift 2 ;;
        --to)                 TO_SHA="${2:-}"; shift 2 ;;
        --init)               MODE="init"; INIT_SHA="${2:-}"; shift 2 ;;
        --commit-sync)        MODE="commit-sync"; shift ;;
        # v2 flags
        --full)               MODE="full-gen"; shift ;;
        --chapter)            CHAPTER="${2:-}"; shift 2 ;;
        --doc)                DOC_FILTER="${2:-}"; shift 2 ;;
        --force-regenerate)   FORCE="force"; shift ;;
        --estimate)           MODE="estimate"; shift ;;
        --list-chapters)      MODE="list-chapters"; shift ;;
        --regenerate-index)   MODE="regen-index"; shift ;;
        --regenerate-sidebar) MODE="regen-sidebar"; shift ;;
        --emit-llms-txt)      MODE="emit-llms-txt"; shift ;;
        -h|--help)            usage ;;
        *)                    log "Unknown flag: $1"; usage ;;
    esac
done

source "$SCRIPTS_DIR/lib/audit.sh"

# ---- v1 sub-modes without pipeline ----
if [ "$MODE" = "init" ]; then
    [ -n "$INIT_SHA" ] || die "--init requires a SHA"
    SRC="$(abs_source_repo)"
    INIT_SHA="$(git -C "$SRC" rev-parse "$INIT_SHA")"
    jq --arg sha "$INIT_SHA" --arg ts "$(date -Iseconds)" \
        '.last_commit_sha=$sha | .timestamp=$ts | .mappings_synced=[]' \
        "$STATE_DIR/last_sync.json" > "$STATE_DIR/last_sync.json.tmp"
    mv "$STATE_DIR/last_sync.json.tmp" "$STATE_DIR/last_sync.json"
    log "Init: last_sync.json set to $INIT_SHA"
    exit 0
fi

if [ "$MODE" = "commit-sync" ]; then
    [ -f "$STATE_DIR/changes.json" ] || die "No changes.json to draw TO sha from"
    TO="$(jq -r '.to_sha' "$STATE_DIR/changes.json")"
    [ "$TO" != "null" ] && [ -n "$TO" ] || die "Invalid to_sha in changes.json"
    IDS="$(jq -c '[.triggered_mappings[].id]' "$STATE_DIR/changes.json")"
    jq --arg sha "$TO" --arg ts "$(date -Iseconds)" --argjson ids "$IDS" \
        '.last_commit_sha=$sha | .timestamp=$ts | .mappings_synced=$ids' \
        "$STATE_DIR/last_sync.json" > "$STATE_DIR/last_sync.json.tmp"
    mv "$STATE_DIR/last_sync.json.tmp" "$STATE_DIR/last_sync.json"
    log "Commit-sync: last_sync.json now at $TO"
    exit 0
fi

# ---- v2 sub-modes ----
if [ "$MODE" = "list-chapters" ]; then
    yaml_get '.chapters | keys[]' | tr -d '"'
    exit 0
fi

if [ "$MODE" = "emit-llms-txt" ]; then
    bash "$SCRIPTS_DIR/lib/llms_txt.sh"
    exit 0
fi

if [ "$MODE" = "regen-sidebar" ]; then
    [ -n "$CHAPTER" ] || die "--regenerate-sidebar requires --chapter"
    bash "$SCRIPTS_DIR/lib/sidebar_gen.sh" "$CHAPTER"
    exit 0
fi

if [ "$MODE" = "regen-index" ]; then
    [ -n "$CHAPTER" ] || die "--regenerate-index requires --chapter"
    bash "$SCRIPTS_DIR/lib/index_gen.sh" "$CHAPTER"
    exit 0
fi

if [ "$MODE" = "estimate" ]; then
    [ -n "$CHAPTER" ] || die "--estimate requires --chapter"
    bash "$SCRIPTS_DIR/lib/resolve.sh" "$CHAPTER" "$DOC_FILTER" "$FORCE"
    bash "$SCRIPTS_DIR/lib/estimate.sh"
    exit 0
fi

if [ "$MODE" = "full-gen" ]; then
    [ -n "$CHAPTER" ] || die "--full requires --chapter"
    audit_start "full" "$CHAPTER" "cli"
    bash "$SCRIPTS_DIR/lib/resolve.sh" "$CHAPTER" "$DOC_FILTER" "$FORCE"
    bash "$SCRIPTS_DIR/lib/full_generate.sh"
    bash "$SCRIPTS_DIR/lib/index_gen.sh" "$CHAPTER"
    bash "$SCRIPTS_DIR/lib/sidebar_gen.sh" "$CHAPTER"
    bash "$SCRIPTS_DIR/lib/llms_txt.sh"
    bash "$SCRIPTS_DIR/lib/output.sh" || log "output.sh non-fatal failure"
    audit_finish 0
    log "Full-gen done. See drafts/SUMMARY.md and drafts/$CHAPTER/"
    exit 0
fi

# ---- v1 incremental pipeline (unchanged) ----
bash "$SCRIPTS_DIR/lib/detect.sh" "$FROM_SHA" "${TO_SHA:-HEAD}"

if [ -n "$ONLY_MAPPING" ]; then
    jq --arg id "$ONLY_MAPPING" \
        '.triggered_mappings = [ .triggered_mappings[] | select(.id==$id) ]' \
        "$STATE_DIR/changes.json" > "$STATE_DIR/changes.json.tmp"
    mv "$STATE_DIR/changes.json.tmp" "$STATE_DIR/changes.json"
    COUNT="$(jq '.triggered_mappings | length' "$STATE_DIR/changes.json")"
    log "Filter --mapping $ONLY_MAPPING: $COUNT mapping(s) remain"
fi

[ "$MODE" = "only-detect" ] && exit 0

bash "$SCRIPTS_DIR/lib/prepare.sh"

[ "$MODE" = "dry-run" ] && { log "Dry-run complete"; exit 0; }

bash "$SCRIPTS_DIR/lib/generate.sh"
bash "$SCRIPTS_DIR/lib/screenshot.sh" || log "Screenshot stage non-fatal failure"
bash "$SCRIPTS_DIR/lib/output.sh"

log "Done. See drafts/SUMMARY.md"
