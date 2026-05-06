#!/usr/bin/env bash
# Stage 1: Detect source changes and match mappings.
# Usage: detect.sh [<from_sha>] [<to_sha>]
# Reads from_sha from state/last_sync.json if not provided.
# Writes state/changes.json.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

FROM_SHA="${1:-}"
TO_SHA="${2:-HEAD}"

if [ -z "$FROM_SHA" ]; then
    FROM_SHA="$(jq -r '.last_commit_sha // empty' "$STATE_DIR/last_sync.json")"
fi

[ -n "$FROM_SHA" ] || die "No from_sha. Run 'sync.sh --init <sha>' first or pass --from."

SRC="$(abs_source_repo)"
[ -d "$SRC/.git" ] || die "Not a git repo: $SRC"

log "Detect: $FROM_SHA .. $TO_SHA in $SRC"

# Resolve real SHAs (handles HEAD, branch names)
FROM_SHA="$(git -C "$SRC" rev-parse "$FROM_SHA")"
TO_SHA="$(git -C "$SRC" rev-parse "$TO_SHA")"

if [ "$FROM_SHA" = "$TO_SHA" ]; then
    log "No changes ($FROM_SHA == $TO_SHA)"
    echo '{"from_sha":"'"$FROM_SHA"'","to_sha":"'"$TO_SHA"'","triggered_mappings":[]}' \
        > "$STATE_DIR/changes.json"
    exit 0
fi

# Get changed file list
CHANGED_FILES="$(git -C "$SRC" diff --name-only "$FROM_SHA" "$TO_SHA")"
if [ -z "$CHANGED_FILES" ]; then
    log "No file changes"
    echo '{"from_sha":"'"$FROM_SHA"'","to_sha":"'"$TO_SHA"'","triggered_mappings":[]}' \
        > "$STATE_DIR/changes.json"
    exit 0
fi

# Match mappings via Python helper (glob handling)
echo "$CHANGED_FILES" | python3 "$SCRIPTS_DIR/lib/match_mappings.py" \
    "$FROM_SHA" "$TO_SHA" "$CONFIG_FILE" > "$STATE_DIR/changes.json"

COUNT="$(jq '.triggered_mappings | length' "$STATE_DIR/changes.json")"
log "Detected $COUNT triggered mapping(s)"
