#!/usr/bin/env bash
# Main entry. Orchestrates the 5-stage docs-sync pipeline.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/common.sh"

MODE="full"            # full | dry-run | only-detect | init | commit-sync
FROM_SHA=""
TO_SHA=""
ONLY_MAPPING=""
INIT_SHA=""

usage() {
    cat <<EOF
Usage: $0 [--dry-run] [--only-detect] [--mapping <id>]
          [--from <sha>] [--to <sha>]
          [--init <sha>] [--commit-sync]
EOF
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)      MODE="dry-run"; shift ;;
        --only-detect)  MODE="only-detect"; shift ;;
        --mapping)      ONLY_MAPPING="${2:-}"; shift 2 ;;
        --from)         FROM_SHA="${2:-}"; shift 2 ;;
        --to)           TO_SHA="${2:-}"; shift 2 ;;
        --init)         MODE="init"; INIT_SHA="${2:-}"; shift 2 ;;
        --commit-sync)  MODE="commit-sync"; shift ;;
        -h|--help)      usage ;;
        *)              log "Unknown flag: $1"; usage ;;
    esac
done

# ---- Sub-modes that don't run the pipeline ----
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

# ---- Pipeline modes ----
# Stage 1
bash "$SCRIPTS_DIR/lib/detect.sh" "$FROM_SHA" "${TO_SHA:-HEAD}"

# Filter mappings by --mapping (in place on changes.json)
if [ -n "$ONLY_MAPPING" ]; then
    jq --arg id "$ONLY_MAPPING" \
        '.triggered_mappings = [ .triggered_mappings[] | select(.id==$id) ]' \
        "$STATE_DIR/changes.json" > "$STATE_DIR/changes.json.tmp"
    mv "$STATE_DIR/changes.json.tmp" "$STATE_DIR/changes.json"
    COUNT="$(jq '.triggered_mappings | length' "$STATE_DIR/changes.json")"
    log "Filter --mapping $ONLY_MAPPING: $COUNT mapping(s) remain"
fi

[ "$MODE" = "only-detect" ] && exit 0

# Stage 2
bash "$SCRIPTS_DIR/lib/prepare.sh"

[ "$MODE" = "dry-run" ] && { log "Dry-run complete"; exit 0; }

# Stage 3
bash "$SCRIPTS_DIR/lib/generate.sh"

# Stage 4
bash "$SCRIPTS_DIR/lib/screenshot.sh" || log "Screenshot stage non-fatal failure"

# Stage 5
bash "$SCRIPTS_DIR/lib/output.sh"

log "Done. See drafts/SUMMARY.md"
